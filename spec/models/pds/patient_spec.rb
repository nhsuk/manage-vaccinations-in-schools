# frozen_string_literal: true

describe PDS::Patient do
  describe ".find" do
    let(:json_response) do
      File.read("spec/support/pds-get-patient-response.json")
    end
    let(:request_id) { "123e4567-e89b-12d3-a456-426614174000" }
    let(:patient_json) do
      File.read(Rails.root.join("spec/fixtures/patient_record.json"))
    end

    before do
      allow(NHS::PDS::Patient).to receive(:find).and_return(
        instance_double(Faraday::Response, status: 200, body: json_response)
      )
    end

    it "calls find_patient on PDS library" do
      described_class.find("9449306168")

      expect(NHS::PDS::Patient).to have_received(:find).with("9449306168")
    end
  end
end
