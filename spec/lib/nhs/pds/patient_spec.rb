# frozen_string_literal: true

describe NHS::PDS::Patient do
  before do
    allow(NHS::API).to receive(:connection).and_return(
      Faraday.new do |builder|
        stubbed_requests.each do |request, response|
          builder.adapter :test do |stub|
            stub.get(request) { response }
          end
        end
      end
    )
  end

  describe ".find" do
    let(:stubbed_requests) do
      [
        [
          "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/9449306168",
          [200, {}, "patient record as json"]
        ]
      ]
    end

    it "sends a GET request to retrieve a patient by their NHS number" do
      response = described_class.find("9449306168").body

      expect(response).to eq "patient record as json"
    end
  end

  describe ".find_by" do
    let(:stubbed_requests) do
      [
        [
          "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient",
          [200, {}, "patient record as json"]
        ]
      ]
    end

    it "sends a GET request to with the provided attributes" do
      response =
        described_class.find_by(
          family: "Lawman",
          gender: "female",
          birthdate: "eq1939-01-09"
        )

      expect(response.body).to eq "patient record as json"
    end

    it "raises an error if an unrecognised attribute is provided" do
      expect {
        described_class.find_by(
          given: "Eldreda",
          family_name: "Lawman",
          date_of_birth: "1939-01-09"
        )
      }.to raise_error("Unrecognised attributes: family_name, date_of_birth")
    end
  end
end
