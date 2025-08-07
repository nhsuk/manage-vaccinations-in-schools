# frozen_string_literal: true

module PDSHelper
  def stub_pds_search_to_return_no_patients
    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including({})).to_return_json(body: { total: 0 })
  end

  def stub_pds_search_to_return_a_patient
    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including({})).to_return(
      body: file_fixture("pds/search-patients-response.json"),
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_get_nhs_number_to_return_a_patient
    stub_request(
      :get,
      Addressable::Template.new(
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/{nhs_number}"
      )
    ).to_return(
      body: file_fixture("pds/get-patient-response.json"),
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_get_nhs_number_to_return_an_invalidated_patient
    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{@patient.nhs_number}"
    ).to_return(
      body: file_fixture("pds/invalid-patient-response.json"),
      status: 404,
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end
end
