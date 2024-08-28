# frozen_string_literal: true

describe NHS::PDS do
  before do
    allow(NHS::API).to receive(:connection).and_return(
      Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.get(
            "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/9000000009"
          ) { [200, {}, {}.to_json] }
        end
      end
    )
  end

  describe ".connection" do
    it "sets the url" do
      expect(
        described_class.connection.url_prefix.to_s
      ).to eq "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4"
    end
  end

  describe NHS::PDS::Patient do
    describe ".find_patient" do
      it "sends a GET request to retrieve a patient by their NHS number" do
        response = described_class.find("9000000009").body

        expect(response).to eq "{}"
      end
    end
  end
end
