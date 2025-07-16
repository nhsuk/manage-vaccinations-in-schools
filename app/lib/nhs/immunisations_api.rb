# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class << self
    def sync_immunisation(vaccination_record)
      if vaccination_record.not_administered? || vaccination_record.discarded?
        raise "Vaccination record delete not supported yet: #{vaccination_record.id}"
      end

      last_synced_at = vaccination_record.nhs_immunisations_api_synced_at
      if last_synced_at.present?
        sync_pending_at =
          vaccination_record.nhs_immunisations_api_sync_pending_at ||
            vaccination_record.updated_at

        if last_synced_at > sync_pending_at
          Rails.logger.info(
            "Vaccination record already synced: #{vaccination_record.id}"
          )
        else
          update_immunisation(vaccination_record)
        end
      else
        record_immunisation(vaccination_record)
      end
    end

    def record_immunisation(vaccination_record)
      unless Flipper.enabled?(:immunisations_fhir_api_integration)
        Rails.logger.info(
          "Not recording vaccination record to immunisations API as the" \
            " feature flag is disabled: #{vaccination_record.id}"
        )
        return
      end

      check_vaccination_record_for_create_or_update(vaccination_record)

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
        raise "Error recording vaccination record #{vaccination_record.id} to" \
                " Immunisations API: unexpected response status" \
                " #{response.status}"
      end
    rescue Faraday::ClientError => e
      if (diagnostics = extract_error_diagnostics(e&.response)).present?
        raise "Error recording vaccination record #{vaccination_record.id} to" \
                " Immunisations API: #{diagnostics}"
      else
        raise
      end
    end

    def update_immunisation(vaccination_record)
      unless Flipper.enabled?(:immunisations_fhir_api_integration)
        Rails.logger.info(
          "Not updating vaccination record to immunisations API as the" \
            " feature flag is disabled: #{vaccination_record.id}"
        )
        return
      end

      check_vaccination_record_for_create_or_update(vaccination_record)

      if vaccination_record.nhs_immunisations_api_id.blank?
        raise "Vaccination record #{vaccination_record.id} missing NHS Immunisation ID"
      end

      if vaccination_record.nhs_immunisations_api_etag.blank?
        raise "Vaccination record #{vaccination_record.id} missing ETag"
      end

      nhs_id = vaccination_record.nhs_immunisations_api_id
      response =
        NHS::API.connection.put(
          "/immunisation-fhir-api/FHIR/R4/Immunization/#{nhs_id}",
          vaccination_record.fhir_record.to_json,
          {
            "Content-Type" => "application/fhir+json",
            "E-Tag" => vaccination_record.nhs_immunisations_api_etag
          }
        )

      if response.status == 200
        vaccination_record.update!(
          nhs_immunisations_api_synced_at: Time.current,
          # This simplistic approach is based on the assumption that the NHS
          # Immunisations API will always simply increment the ETag. Alternative
          # approaches are to perform a GET after this POST to get the ETag, or
          # to update our record before we do this POST, which would mean we
          # don't need to store the ETag at all.
          #
          # However at this time it's our understanding that the API will always
          # increment the ETag, and, practically speaking, it's very unlikely
          # that our record would be updated by someone else. Hence this simple
          # approach.
          nhs_immunisations_api_etag:
            vaccination_record.nhs_immunisations_api_etag.to_i + 1
        )
      else
        raise "Error updating vaccination record #{vaccination_record.id} to" \
                " Immunisations API: unexpected response status" \
                " #{response.status}"
      end
    rescue Faraday::ClientError => e
      if (diagnostics = extract_error_diagnostics(e&.response)).present?
        raise "Error updating vaccination record #{vaccination_record.id} to" \
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

    def check_vaccination_record_for_create_or_update(vaccination_record)
      if vaccination_record.not_administered?
        raise "Vaccination record is not administered: #{vaccination_record.id}"
      end

      if vaccination_record.discarded?
        raise "Vaccination record is discarded: #{vaccination_record.id}"
      end

      if vaccination_record.patient.nhs_number.blank?
        raise "PatientVaccination record is discarded: #{vaccination_record.id}"
      end
    end
  end
end
