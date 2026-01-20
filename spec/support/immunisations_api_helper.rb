# frozen_string_literal: true

module ImmunisationsAPIHelper
  def stub_immunisations_api_post(*uuids, uuid: Random.uuid)
    uuids << uuid
    responses =
      uuids.map do |id|
        {
          status: 201,
          body: nil,
          headers: {
            location:
              "https://localhost:4000/immunisation-fhir-api/Immunization/#{id}"
          }
        }
      end

    stub_request(
      :post,
      "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
    ).to_return(responses)
  end

  def stub_immunisations_api_put(uuid: Random.uuid)
    stub_request(
      :put,
      "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/#{uuid}"
    ).to_return(status: 200, body: nil)
  end

  def stub_immunisations_api_delete(uuid: Random.uuid)
    stub_request(
      :delete,
      "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/#{uuid}"
    ).to_return(status: 204, body: nil)
  end
end
