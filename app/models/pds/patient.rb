# frozen_string_literal: true

class PDS::Patient
  include ActiveModel::Model

  attr_accessor :nhs_number, :given_name, :family_name, :date_of_birth

  class << self
    def find(nhs_number)
      response = NHS::PDS.get_patient(nhs_number)
      from_pds_fhir_response(response.body)
    end

    private

    def from_pds_fhir_response(response)
      new(
        nhs_number: response["id"],
        given_name: response["name"][0]["given"][0],
        family_name: response["name"][0]["family"],
        date_of_birth: response["birthDate"]
      )
    end
  end
end
