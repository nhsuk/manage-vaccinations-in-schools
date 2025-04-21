# frozen_string_literal: true

describe PatientNHSNumberLookupWithPendingChangesJob do
  subject(:perform_now) { described_class.perform_now(patient) }

  let(:programme) { create(:programme) }

  before { create(:gp_practice, ods_code: "H81109") }

  context "with an NHS number already" do
    let(:patient) do
      create(
        :patient,
        nhs_number: nil,
        pending_changes: {
          nhs_number: "0123456789"
        }
      )
    end

    it "doesn't change the NHS number" do
      expect { perform_now }.not_to change(patient, :pending_changes)
    end
  end

  shared_examples "an NHS number lookup" do
    before do
      stub_request(
        :get,
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
      ).with(
        query: {
          "_history" => "true",
          "address-postalcode" => "SW11 1AA",
          "birthdate" => "eq2014-02-18",
          "family" => "Smith",
          "given" => "John"
        }
      ).to_return(
        body: file_fixture(response_file),
        headers: {
          "Content-Type" => "application/fhir+json"
        }
      )
    end

    context "without a match" do
      let(:response_file) { "pds/search-patients-no-results-response.json" }

      it "doesn't change the NHS number" do
        expect { perform_now }.not_to change(patient, :pending_changes)
      end
    end

    context "with a match" do
      let(:response_file) { "pds/search-patients-response.json" }

      it "sets the NHS number of the patient" do
        expect { perform_now }.to change {
          patient.reload.with_pending_changes.nhs_number
        }.to("9449306168")
      end

      it "marks the patient as not invalidated" do
        perform_now
        expect(patient.reload.with_pending_changes).not_to be_invalidated
      end
    end
  end

  context "with an NHS number already but invalidated" do
    let(:organisation) { create(:organisation, programmes: [programme]) }

    let(:patient) do
      create(
        :patient,
        nhs_number: "0123456789",
        invalidated_at: Time.current,
        organisation:,
        pending_changes: {
          given_name: "John",
          family_name: "Smith",
          date_of_birth: Date.new(2014, 2, 18),
          address_postcode: "SW11 1AA"
        }
      )
    end

    it_behaves_like "an NHS number lookup"
  end

  context "without an NHS number" do
    let(:patient) do
      create(
        :patient,
        nhs_number: nil,
        pending_changes: {
          given_name: "John",
          family_name: "Smith",
          date_of_birth: Date.new(2014, 2, 18),
          address_postcode: "SW11 1AA"
        }
      )
    end

    it_behaves_like "an NHS number lookup"
  end
end
