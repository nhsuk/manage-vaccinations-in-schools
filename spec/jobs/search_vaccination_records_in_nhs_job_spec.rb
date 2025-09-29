# frozen_string_literal: true

describe SearchVaccinationRecordsInNHSJob do
  subject(:perform) { described_class.new.perform(patient.id) }

  let(:team) { create(:team) }
  let(:school) { create(:school, team:) }
  let(:patient) { create(:patient, team:, school:, nhs_number:) }
  let(:nhs_number) { "9449308357" }
  let!(:programme) { create(:programme, :flu) }

  before do
    Flipper.enable(:imms_api_integration)
    Flipper.enable(:imms_api_search_job)
  end

  after do
    Flipper.disable(:imms_api_integration)
    Flipper.disable(:imms_api_search_job)
  end

  describe "#extract_vaccination_records" do
    let(:bundle) do
      FHIR.from_contents(
        file_fixture("fhir/search_response_2_results.json").read
      )
    end

    it "returns only Immunization resources from the bundle" do
      records = described_class.new.extract_vaccination_records(bundle)
      expect(records).to all(have_attributes(resourceType: "Immunization"))
      expect(records.size).to eq 2
    end
  end

  describe "#perform" do
    shared_examples "calls StatusUpdater" do
      it "calls StatusUpdater with the patient" do
        expect(StatusUpdater).to receive(:call).with(patient:)
        perform
      end
    end

    shared_examples "sends discovery comms if required once" do
      it "calls send_vaccination_discovered_if_required once" do
        expect(AlreadyHadNotificationSender).to receive(:call).once

        perform
      end
    end

    shared_examples "sends discovery comms if required twice" do
      it "calls send_vaccination_discovered_if_required twice" do
        expect(AlreadyHadNotificationSender).to receive(:call).twice

        perform
      end
    end

    shared_examples "doesn't send discovery comms" do
      it "does not call send_vaccination_discovered_if_required" do
        expect(AlreadyHadNotificationSender).not_to receive(:call)

        perform
      end
    end

    let(:expected_query) do
      {
        "patient.identifier" =>
          "https://fhir.nhs.uk/Id/nhs-number|#{patient.nhs_number}",
        "-immunization.target" => "FLU"
      }
    end
    let(:status) { 200 }
    let(:body) { file_fixture("fhir/search_response_2_results.json").read }
    let(:headers) { { "content-type" => "application/fhir+json" } }

    let(:existing_bundle) do
      FHIR.from_contents(
        file_fixture("fhir/search_response_0_results.json").read
      )
    end
    let!(:existing_records) do
      fhir_records =
        described_class.new.extract_vaccination_records(existing_bundle)
      mapped_records =
        fhir_records.map do |fhir_record|
          mapped =
            FHIRMapper::VaccinationRecord.from_fhir_record(
              fhir_record,
              patient:
            )
          mapped.save!

          mapped
        end

      mapped_records
    end

    before do
      stub_request(
        :get,
        "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
      ).with(query: expected_query).to_return(status:, body:, headers:)
    end

    context "with 2 new incoming records" do
      it "creates new vaccination records for incoming Immunizations" do
        expect { perform }.to change { patient.vaccination_records.count }.by(2)
      end

      include_examples "calls StatusUpdater"
    end

    context "with 1 existing record and 1 new incoming record" do
      let(:existing_bundle) do
        FHIR.from_contents(
          file_fixture("fhir/search_response_1_result.json").read
        )
      end

      it "updates existing records and creates new records not present" do
        expect { perform }.to change { patient.vaccination_records.count }.by(1)
        expect(patient.vaccination_records.map(&:id)).to include(
          existing_records.map(&:id).first
        )
        expect(existing_records.first.reload.performed_at).to eq(
          Time.parse("2025-08-22T14:16:03+01:00")
        )
      end

      include_examples "calls StatusUpdater"
    end

    context "with 2 existing records and only 1 incoming (edited) record" do
      let(:existing_bundle) do
        FHIR.from_contents(
          file_fixture("fhir/search_response_2_results.json").read
        )
      end
      let(:body) { file_fixture("fhir/search_response_1_result.json").read }

      it "deletes the record that is no longer present, and edits the existing record" do
        expect { perform }.to change { patient.vaccination_records.count }.by(
          -1
        )
        expect(patient.vaccination_records.count).to eq(1)
        expect(existing_records.map(&:id)).to include(
          patient.vaccination_records.map(&:id).first
        )
        expect(patient.vaccination_records.first&.performed_at).to eq(
          Time.parse("2025-08-23T14:16:03+01:00")
        )
      end

      include_examples "calls StatusUpdater"
    end

    context "with a mavis record in the search results" do
      let(:body) do
        file_fixture("fhir/search_response_1_result_mavis.json").read
      end

      it "does not create a new record" do
        expect { perform }.not_to(change { patient.vaccination_records.count })
      end

      include_examples "calls StatusUpdater"
    end

    context "with the feature flag disabled" do
      before { Flipper.disable(:imms_api_search_job) }

      it "does not change any records locally" do
        expect { perform }.not_to(change { patient.vaccination_records.count })
      end
    end

    context "with a non-api record already on the patient" do
      let!(:vaccination_record) do
        create(:vaccination_record, patient:, programme:)
      end

      it "does not change the record which was recorded in service" do
        expect { perform }.not_to(change(vaccination_record, :reload))

        expect(patient.vaccination_records.count).to be 3
        expect(patient.vaccination_records.map(&:source)).to contain_exactly(
          "historical_upload",
          "nhs_immunisations_api",
          "nhs_immunisations_api"
        )
      end

      include_examples "calls StatusUpdater"
    end

    context "with no NHS number" do
      let(:nhs_number) { nil }

      let(:existing_bundle) do
        FHIR.from_contents(
          file_fixture("fhir/search_response_2_results.json").read
        )
      end

      it "deletes all the API records and does not create any new ones" do
        expect { perform }.to change { patient.vaccination_records.count }.by(
          -2
        )
        expect(patient.vaccination_records.count).to eq(0)
      end

      include_examples "calls StatusUpdater"
    end
  end
end
