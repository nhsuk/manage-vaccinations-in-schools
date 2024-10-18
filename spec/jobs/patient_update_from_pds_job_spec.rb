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
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/0123456789"
      ).to_return(
        body: file_fixture("pds/get-patient-response.json"),
        headers: {
          "Content-Type" => "application/fhir+json"
        }
      )
    end

    let(:patient) { create(:patient, nhs_number: "0123456789") }

    it "updates the patient details from PDS" do
      expect(patient).to receive(:update_from_pds!)
      perform_now
    end
  end
end
