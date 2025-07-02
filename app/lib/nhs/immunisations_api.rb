# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class << self
    def record_immunisation(vaccination_record)
      NHS::API.connection.post(
        "/immunisation-fhir-api/FHIR/R4/Immunization",
        vaccination_record.fhir_record.to_json,
        "Content-Type" => "application/fhir+json"
      )
    rescue Faraday::ClientError => e
      if (diagnostics = extract_error_diagnostics(e&.response)).present?
        raise "Error syncing vaccination #{vaccination_record.id} record to" \
                " Immunisations API: #{diagnostics}"
      else
        raise
      end
    end

    private

    def extract_error_diagnostics(response)
      return nil if response.nil? || response[:body].blank?

      begin
        JSON.parse(response[:body], symbolize_names: true).dig(
          :issue,
          0,
          :diagnostics
        )
      rescue JSON::ParserError
        nil
      end
    end
  end
end
