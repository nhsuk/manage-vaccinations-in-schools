# frozen_string_literal: true

module ImmunisationsAPIHelper
  def stub_immunisations_api_post(uuid: Random.uuid)
    stub_request(
      :post,
      "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
    ).to_return(
      status: 201,
      body: nil,
      headers: {
        location:
          "https://localhost:4000/immunisation-fhir-api/Immunization/#{uuid}"
      }
    )
  end

  def stub_immunisations_api_put(uuid: Random.uuid)
    stub_request(
      :put,
      "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/#{uuid}"
    ).to_return(status: 200, body: nil)
  end
end
