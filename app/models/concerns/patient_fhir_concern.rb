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
        ]
        # FIXME: Do we need the following fields or is NHS number enough?
        # name: [FHIR::HumanName.new(family: family_name, given: given_name)],
        # birthDate: birth_date,
        # gender: gender_fhir_value,
        # address: [
        #   FHIR::Address.new(
        #     line: [address_line_1, address_line_2],
        #     city: address_town,
        #     postalCode: address_postcode
        #   )
        # ]
      )
    end

    # FIXME: Only necessary if we need to send this through.
    # def gender_fhir_value
    #   case gender
    #   when :not_known
    #     "unknown"
    #   when :not_specified
    #     "other"
    #   else
    #     gender
    #   end
    # end

    def fhir_id
      "Patient/#{id}"
    end
  end
end
