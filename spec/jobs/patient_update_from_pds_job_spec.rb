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

  context "invalidated patient" do
    let!(:patient) { create(:patient, :invalidated) }

    it "doesn't update the patient" do
      expect(patient).not_to receive(:update_from_pds!)
      perform_now
    end
  end

  context "with an NHS number" do
    context "when the patient is valid" do
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
          expect { perform_now }.to change(patient, :nhs_number).to(
            "9000000009"
          )
        end

        context "when a patient already exists for the new NHS number" do
          before { create(:patient, nhs_number: "9000000009") }

          it "deletes the patient without an NHS number" do
            expect { perform_now }.to change(Patient, :count).by(-1)
            expect { patient.reload }.to raise_error(
              ActiveRecord::RecordNotFound
            )
          end
        end
      end
    end

    context "when the patient is invalid" do
      before do
        stub_request(
          :get,
          "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/9000000009"
        ).to_return(
          body: file_fixture("pds/invalid-patient-response.json"),
          status: 404,
          headers: {
            "Content-Type" => "application/fhir+json"
          }
        )
      end

      let(:patient) { create(:patient, nhs_number: "9000000009") }

      it "marks the patient as invalid" do
        expect(patient).to receive(:invalidate!)
        perform_now
      end
    end
  end
end
