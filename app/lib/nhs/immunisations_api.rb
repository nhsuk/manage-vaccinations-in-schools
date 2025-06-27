# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class PatientNotFound < StandardError
  end

  class << self
    def record_immunisation(vaccination_record)
      NHS::API.connection.post(
        "/immunisation-fhir-api/FHIR/R4/Immunization",
        vaccination_record.fhir_record.to_json,
        "Content-Type" => "application/fhir+json"
      )
    rescue Faraday::Error => e
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

      if response.empty?
        { code: nil, diagnostics: "No response body" }
      elsif response[:issue].blank?
        { code: nil, diagnostics: "No issues in response" }
      elsif response[:issue].first[:severity] != "error"
        { code: nil, diagnostics: "Issue is not an error" }
      else
        diagnostics = response[:issue].first[:diagnostics]
        if diagnostics.match?(/NHS Number: \d{10} is invalid.*/)
          diagnostics.replace("NHS Number is invalid or it doesn't exist")
        end

        { code: response[:issue].first[:code], diagnostics: diagnostics }
      end
    end
  end
end
