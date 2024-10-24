# frozen_string_literal: true

describe PatientNHSNumberLookupJob do
  subject(:perform_now) { described_class.perform_now(patient) }

  context "with an NHS number already" do
    let(:patient) { create(:patient, nhs_number: "0123456789") }

    it "doesn't change the NHS number" do
      expect { perform_now }.not_to change(patient, :nhs_number)
    end
  end

  context "without an NHS number" do
    let!(:patient) do
      create(
        :patient,
        nhs_number: nil,
        given_name: "John",
        family_name: "Smith",
        date_of_birth: Date.new(2014, 2, 18),
        address_postcode: "SW11 1AA"
      )
    end

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

    context "with a match" do
      let(:response_file) { "pds/search-patients-response.json" }

      it "sets the NHS number of the patient" do
        expect { perform_now }.to change(patient, :nhs_number).from(nil).to(
          "9449306168"
        )
      end

      it "updates the patient details from PDS" do
        expect(patient).to receive(:update_from_pds!)
        perform_now
      end
    end

    context "without a match" do
      let(:response_file) { "pds/search-patients-no-results-response.json" }

      it "doesn't change the NHS number" do
        expect { perform_now }.not_to change(patient, :nhs_number)
      end
    end

    context "with a match and the patient already exists" do
      let(:response_file) { "pds/search-patients-response.json" }

      let!(:existing_patient) { create(:patient, nhs_number: "9449306168") }

      let(:programme) { create(:programme) }
      let(:patient_session) { create(:patient_session, patient:, programme:) }
      let(:gillick_assessment) { create(:gillick_assessment, patient_session:) }
      let(:triage) { create(:triage, patient:, programme:) }
      let(:vaccination_record) do
        create(:vaccination_record, patient_session:, programme:)
      end

      context "when the existing patient is not already in the session" do
        it "deletes the patient without an NHS number" do
          expect { perform_now }.to change(Patient, :count).by(-1)
        end

        it "moves the gillick assessments" do
          expect { perform_now }.to change {
            gillick_assessment.reload.patient
          }.from(patient).to(existing_patient)
        end

        it "moves the triages" do
          expect { perform_now }.to change { triage.reload.patient }.from(
            patient
          ).to(existing_patient)
        end

        it "moves the vaccination records" do
          expect { perform_now }.to change {
            vaccination_record.reload.patient
          }.from(patient).to(existing_patient)
        end
      end

      context "when the existing patient is already in the session" do
        before do
          create(
            :patient_session,
            patient: existing_patient,
            session: patient_session.session
          )
        end

        it "deletes the patient without an NHS number" do
          expect { perform_now }.to change(Patient, :count).by(-1)
        end

        it "moves the gillick assessments" do
          expect { perform_now }.to change {
            gillick_assessment.reload.patient
          }.from(patient).to(existing_patient)
        end

        it "moves the triages" do
          expect { perform_now }.to change { triage.reload.patient }.from(
            patient
          ).to(existing_patient)
        end

        it "moves the vaccination records" do
          expect { perform_now }.to change {
            vaccination_record.reload.patient
          }.from(patient).to(existing_patient)
        end
      end
    end
  end
end
