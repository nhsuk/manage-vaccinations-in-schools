# frozen_string_literal: true

describe PDS::Patient do
  describe "#find" do
    let(:json_response) { file_fixture("pds/get-patient-response.json").read }

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
