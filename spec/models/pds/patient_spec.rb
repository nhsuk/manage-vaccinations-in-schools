# frozen_string_literal: true

describe PDS::Patient do
  describe "#find" do
    let(:json_response) { file_fixture("pds/get-patient-response.json").read }

    before do
      allow(NHS::PDS).to receive(:get_patient).and_return(
        instance_double(
          Faraday::Response,
          status: 200,
          body: JSON.parse(json_response)
        )
      )
    end

    it "calls get_patient on PDS library" do
      described_class.find("9449306168")

      expect(NHS::PDS).to have_received(:get_patient).with("9449306168")
    end
  end
end
