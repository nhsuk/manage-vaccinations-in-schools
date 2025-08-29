# frozen_string_literal: true

module PDSHelper
  def stub_pds_search_to_return_no_patients(**query)
    query["_history"] ||= "true"
    query.delete("_history") if query["_history"] == "false"

    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including(query)).to_return_json(
      body: {
        total: 0
      },
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_search_to_return_a_patient(nhs_number = "9449306168", **query)
    query["_history"] ||= "true"

    response_data =
      JSON.parse(file_fixture("pds/search-patients-response.json").read)

    patient_resource = response_data["entry"][0]["resource"]

    patient_resource["id"] = nhs_number
    patient_resource["identifier"][0]["value"] = nhs_number
    response_data["entry"][0][
      "fullUrl"
    ] = "https://int.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{nhs_number}"

    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including(query)).to_return(
      body: response_data.to_json,
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_search_to_return_too_many_matches(**query)
    query["_history"] ||= "true"

    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including(query)).to_return(
      body: file_fixture("pds/too-many-matches.json"),
      status: 200,
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_get_nhs_number_to_return_a_patient(nhs_number = "{nhs_number}")
    stub_request(
      :get,
      Addressable::Template.new(
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{nhs_number}"
      )
    ).to_return(
      body: file_fixture("pds/get-patient-response.json"),
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_get_nhs_number_to_return_an_invalidated_patient(nhs_number = nil)
    nhs_number ||= @patient.nhs_number

    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{nhs_number}"
    ).to_return(
      body: file_fixture("pds/invalid-patient-response.json"),
      status: 404,
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  def stub_pds_get_nhs_number_to_return_an_invalid_nhs_number_response(
    nhs_number = nil
  )
    nhs_number ||= @patient.nhs_number

    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{nhs_number}"
    ).to_return(
      body: file_fixture("pds/invalid-nhs-number-response.json"),
      status: 400,
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end
end
