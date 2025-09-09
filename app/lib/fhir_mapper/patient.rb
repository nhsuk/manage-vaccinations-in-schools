# frozen_string_literal: true

module FHIRMapper
  class Patient
    delegate_missing_to :@patient

    def initialize(patient)
      @patient = patient
    end

    def fhir_record(reference_id: nil)
      FHIR::Patient.new(
        # The id may be optional, but it's currently needed by the immunisation
        # record so setting it by default for now.
        id: reference_id,
        identifier: [
          FHIR::Identifier.new(
            system: "https://fhir.nhs.uk/Id/nhs-number",
            value: nhs_number
          )
        ],
        name: [FHIR::HumanName.new(family: family_name, given: given_name)],
        birthDate: date_of_birth&.strftime("%Y-%m-%d"),
        gender: gender_fhir_value,
        address: [FHIR::Address.new(postalCode: address_postcode || "ZZ99 3CZ")]
      )
    end

    private

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
  end
end
