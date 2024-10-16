# frozen_string_literal: true

describe NHS::PDS do
  describe "#get_patient" do
    before do
      stub_request(
        :get,
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/9000000009"
      ).to_return(
        body: file_fixture("pds/get-patient-response.json"),
        headers: {
          "Content-Type" => "application/fhir+json"
        }
      )
    end

    it "sends a GET request to retrieve a patient by their NHS number" do
      response = described_class.get_patient("9000000009")
      expect(response.body).to include("id" => "9000000009")
    end
  end

  describe "#search_patients" do
    before do
      stub_request(
        :get,
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
      ).with(
        query: {
          birthdate: "eq1939-01-09",
          family: "Lawman",
          gender: "female"
        }
      ).to_return(
        body: file_fixture("pds/search-patients-response.json"),
        headers: {
          "Content-Type" => "application/fhir+json"
        }
      )
    end

    it "sends a GET request to with the provided attributes" do
      response =
        described_class.search_patients(
          family: "Lawman",
          gender: "female",
          birthdate: "eq1939-01-09"
        )

      expect(response.body).to include("total" => 1)
    end

    it "raises an error if an unrecognised attribute is provided" do
      expect {
        described_class.search_patients(
          given: "Eldreda",
          family_name: "Lawman",
          date_of_birth: "1939-01-09"
        )
      }.to raise_error("Unrecognised attributes: family_name, date_of_birth")
    end
  end
end
