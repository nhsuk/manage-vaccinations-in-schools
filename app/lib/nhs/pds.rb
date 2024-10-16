# frozen_string_literal: true

module NHS::PDS
  SEARCH_FIELDS = %w[
    _fuzzy-match
    _exact-match
    _history
    _max-results
    family
    given
    gender
    birthdate
    death-date
    email
    phone
    address-postalcode
    general-practitioner
  ].freeze

  class << self
    def get_patient(nhs_number)
      NHS::API.connection.get(
        "personal-demographics/FHIR/R4/Patient/#{nhs_number}"
      )
    end

    def search_patients(attributes)
      if (missing_attrs = (attributes.keys.map(&:to_s) - SEARCH_FIELDS)).any?
        raise "Unrecognised attributes: #{missing_attrs.join(", ")}"
      end

      NHS::API.connection.get(
        "personal-demographics/FHIR/R4/Patient",
        attributes
      )
    end
  end
end
