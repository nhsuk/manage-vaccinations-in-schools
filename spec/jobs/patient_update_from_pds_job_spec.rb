# frozen_string_literal: true

describe PatientUpdateFromPDSJob do
  subject(:perform_now) { described_class.perform_now(patient) }

  context "without an NHS number" do
    let(:patient) { create(:patient, nhs_number: nil) }

    it "raises an error" do
      expect { perform_now }.to raise_error(
        PatientUpdateFromPDSJob::MissingNHSNumber
      )
    end
  end

  context "with an NHS number" do
    before do
      stub_request(
        :get,
        Addressable::Template.new(
          "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/{nhs_number}"
        )
      ).to_return(
        body: file_fixture("pds/get-patient-response.json"),
        headers: {
          "Content-Type" => "application/fhir+json"
        }
      )
    end

    let!(:patient) { create(:patient, nhs_number: "9000000009") }

    it "updates the patient details from PDS" do
      expect(patient).to receive(:update_from_pds!)
      perform_now
    end

    it "doesn't change the NHS number" do
      expect { perform_now }.not_to change(patient, :nhs_number)
    end

    it "doesn't delete the patient number" do
      expect { perform_now }.not_to change(Patient, :count)
    end

    context "when the NHS number for the patient has changed" do
      let!(:patient) { create(:patient, nhs_number: "0123456789") }

      it "updates the NHS number" do
        expect { perform_now }.to change(patient, :nhs_number).to("9000000009")
      end

      context "when a patient already exists for the new NHS number" do
        before { create(:patient, nhs_number: "9000000009") }

        it "deletes the patient without an NHS number" do
          expect { perform_now }.to change(Patient, :count).by(-1)
          expect { patient.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
