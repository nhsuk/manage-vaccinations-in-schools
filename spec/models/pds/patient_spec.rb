require "rails_helper"

describe PDS::Patient do
  describe ".find" do
    let(:json_response) do
      File.read("spec/support/pds-get-patient-response.json")
    end
    let(:request_id) { "123e4567-e89b-12d3-a456-426614174000" }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(request_id)
      stub_request(
        :get,
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/9000000009"
      ).with(headers: { "X-Request-ID" => request_id }).to_return(
        status: 200,
        body: json_response
      )
    end

    it "returns a patient with the correct attributes" do
      patient = described_class.find("9000000009")

      expect(patient.nhs_number).to eq("9000000009")
      expect(patient.given_name).to eq("Jane")
      expect(patient.family_name).to eq("Smith")
      expect(patient.date_of_birth).to eq("2010-10-22")
    end
  end
end
