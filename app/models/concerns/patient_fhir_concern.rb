# frozen_string_literal: true

# https://www.hl7.org/fhir/R4/patient.html
module PatientFHIRConcern
  extend ActiveSupport::Concern

  included do
    def to_fhir
      FHIR::Patient.new(
        # The id may be optional, but it's currently needed by the immunisation
        # record so setting it by default for now.
        id: fhir_id,
        identifier: [
          FHIR::Identifier.new(
            system: "https://fhir.nhs.uk/Id/nhs-number",
            value: nhs_number
          )
        ],
        name: [FHIR::HumanName.new(family: family_name, given: given_name)],
        birthDate: date_of_birth&.strftime("%Y-%m-%d"),
        gender: gender_fhir_value,
        address: [FHIR::Address.new(postalCode: address_postcode)]
      )
    end

    def gender_fhir_value
      case gender_code
      when "not_known"
        "unknown"
      when "not_specified"
        "other"
      else
        gender_code
      end
    end

    def fhir_id
      "Patient/#{id}"
    end
  end
end
