class PDS::Patient
  include ActiveModel::Model

  attr_accessor :nhs_number, :given_name, :family_name, :date_of_birth

  class << self
    def find(nhs_number)
      response =
        JSON.parse(
          Net::HTTP.get(
            URI(
              "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{nhs_number}"
            ),
            "X-Request-ID": SecureRandom.uuid
          )
        )
      from_pds_fhir_response(response)
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
