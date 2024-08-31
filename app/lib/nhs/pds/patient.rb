# frozen_string_literal: true

module NHS::PDS::Patient
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
    address-postcode
    general-practitioner
  ].freeze
  class << self
    def find(nhs_number)
      NHS::PDS.connection.get("Patient/#{nhs_number}")
    end

    def find_by(**attributes)
      if (missing_attrs = (attributes.keys.map(&:to_s) - SEARCH_FIELDS)).any?
        raise "Unrecognised attributes: #{missing_attrs.join(", ")}"
      end

      NHS::PDS.connection.get("Patient", attributes)
    end
  end
end
