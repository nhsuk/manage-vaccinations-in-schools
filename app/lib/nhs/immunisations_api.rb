# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class << self
    def record_immunisation(vaccination_record)
      response =
        NHS::API.connection.post(
          "/immunisation-fhir-api/FHIR/R4/Immunization",
          vaccination_record.fhir_record.to_json,
          "Content-Type" => "application/fhir+json"
        )

      if response.status == 201
        vaccination_record.update!(
          nhs_immunisations_api_id:
            extract_nhs_id(response.headers.fetch("location")),
          nhs_immunisations_api_synced_at: Time.current,
          # We would normally retrieve this from the API response, but the NHS
          # Immunisations API does not return this to us, yet.
          nhs_immunisations_api_etag: 1
        )
      else
        raise "Error syncing vaccination record #{vaccination_record.id} to" \
                " Immunisations API: unexpected response status" \
                " #{response.status}"
      end
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

    def extract_nhs_id(location)
      if (match = location.match(%r{Immunization/([a-f0-9-]+)}))
        match[1]
      else
        raise UnrecognisedLocation, location
      end
    end
  end
end
