# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class PatientNotFound < StandardError
  end

  class << self
    def record_immunisation(vaccination_record)
      NHS::API.connection.post(
        "/immunisation-fhir-api/FHIR/R4/Immunization",
        vaccination_record.to_fhir.to_json,
        "Content-Type" => "application/fhir+json"
      )
    rescue StandardError => e
      info = extract_error_info(e.response[:body])
      Rails.logger.error(
        "Error recording vaccination record (#{vaccination_record.id}):" \
          " [#{info[:code]}] #{info[:diagnostics]}"
      )
      raise e
    end

    def extract_error_info(response_body)
      return { code: nil, diagnostics: "No response body" } unless response_body

      response = JSON.parse(response_body, symbolize_names: true)
      return { code: nil, diagnostics: "No response body" } if response.empty?
      if response[:issue].blank?
        return { code: nil, diagnostics: "No issues in response" }
      end

      # TODO: We need to filter out any NHS numbers or other PII here, so
      # shouldn't log the message verbatim here.
      unless response[:issue].first[:severity] == "error"
        return { code: nil, diagnostics: "Issue is not an error" }
      end

      {
        code: response[:issue].first[:code],
        diagnostics: response[:issue].first[:diagnostics]
      }
    end
  end
end
