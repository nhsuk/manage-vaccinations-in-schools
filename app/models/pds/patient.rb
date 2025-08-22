# frozen_string_literal: true

class PDS::Patient
  include ActiveModel::Model

  attr_accessor :nhs_number,
                :family_name,
                :date_of_birth,
                :date_of_death,
                :restricted,
                :gp_ods_code

  class << self
    def find(nhs_number)
      response = NHS::PDS.get_patient(nhs_number)
      from_pds_fhir_response(response.body)
    end

    def search(
      family_name:,
      given_name:,
      date_of_birth:,
      address_postcode:,
      history: nil,
      fuzzy: nil
    )
      query = {
        "family" => family_name,
        "given" => given_name,
        "birthdate" => "eq#{date_of_birth}",
        "address-postalcode" => address_postcode,
        "_history" => history, # look up previous names and addresses,
        "_fuzzy-match" => fuzzy
      }.compact_blank

      results = NHS::PDS.search_patients(query).body

      return if results["total"].zero?

      from_pds_fhir_response(results["entry"].first["resource"])
    end

    private

    def from_pds_fhir_response(response)
      new(
        nhs_number: response["id"],
        family_name: response["name"][0]["family"],
        date_of_birth: Date.parse(response["birthDate"]),
        date_of_death:
          if (deceased_date_time = response["deceasedDateTime"]).present?
            Time.zone.parse(deceased_date_time).to_date
          end,
        restricted:
          response.dig("meta", "security")&.any? { _1["code"] == "R" },
        gp_ods_code:
          response.dig("generalPractitioner", 0, "identifier", "value")
      )
    end
  end
end
