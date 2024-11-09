# frozen_string_literal: true

module PDSHelper
  def stub_pds_search_to_return_no_patients
    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including({})).to_return_json(body: { total: 0 })
  end
end
