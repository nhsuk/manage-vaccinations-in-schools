# frozen_string_literal: true

describe NHS::ImmunisationsAPI do
  include FHIRHelper

  let(:patient) { create(:patient) }
  let(:vaccination_record) { create(:vaccination_record, patient:) }

  describe "record_immunisation" do
    it "sends the correct JSON payload" do
      # TODO: We should use the static immunisation JSON fixture and compare
      #       against that by setting the appropriate attributes on
      #       vaccination_record
      expected_body = vaccination_record.to_fhir.to_json

      stub_request(
        :post,
        "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/"
      ).with(
        body: expected_body,
        headers: {
          "Accept" => "application/fhir+json",
          "Content-Type" => "application/fhir+json"
        }
      ).to_return(status: 200, body: "", headers: {})

      described_class.record_immunisation(vaccination_record)

      expect(
        a_request(
          :post,
          "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/"
        )
      ).to have_been_made
    end
  end
end
