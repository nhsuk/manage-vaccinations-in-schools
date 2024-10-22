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

  class InvalidatedResource < StandardError
  end

  class InvalidNHSNumber < StandardError
  end

  class << self
    def get_patient(nhs_number)
      NHS::API.connection.get(
        "personal-demographics/FHIR/R4/Patient/#{nhs_number}"
      )
    rescue Faraday::BadRequestError => e
      if is_error?(e, "INVALID_RESOURCE_ID")
        raise InvalidNHSNumber, nhs_number
      else
        raise
      end
    rescue Faraday::ResourceNotFound => e
      if is_error?(e, "INVALIDATED_RESOURCE")
        raise InvalidatedResource, nhs_number
      else
        raise
      end
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

    private

    def is_error?(error, code)
      response = JSON.parse(error.response_body)

      response["issue"].any? do |issue|
        issue["details"]["coding"].any? { |coding| coding["code"] == code }
      end
    end
  end
end
