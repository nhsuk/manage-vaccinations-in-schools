# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class BundleLinkParamsMismatch < StandardError
  end

  class OperationOutcomeInBundle < StandardError
  end

  class << self
    def sync_immunisation(vaccination_record)
      case next_sync_action(vaccination_record)
      when :create
        create_immunisation(vaccination_record)
      when :update
        update_immunisation(vaccination_record)
      when :delete
        delete_immunisation(vaccination_record)
      else
        Rails.logger.info(
          "Vaccination record does not require syncing: #{vaccination_record.id}"
        )
      end
    end

    def create_immunisation(vaccination_record)
      unless Flipper.enabled?(:imms_api_integration)
        Rails.logger.info(
          "Not recording vaccination record to immunisations API as the" \
            " feature flag is disabled: #{vaccination_record.id}"
        )
        return
      end

      check_vaccination_record_for_create_or_update(vaccination_record)

      Rails.logger.info(
        "Recording vaccination record to immunisations API:" \
          " #{vaccination_record.id}"
      )

      response, duration =
        execute_and_time do
          NHS::API.connection.post(
            "/immunisation-fhir-api/FHIR/R4/Immunization",
            vaccination_record.fhir_record.to_json,
            "Content-Type" => "application/fhir+json"
          )
        end

      Rails.logger.info(
        "Create response returned with status #{response.status} in #{duration}s"
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
      unless Flipper.enabled?(:imms_api_integration)
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

      Rails.logger.info(
        "Updating vaccination record in immunisations API:" \
          " #{vaccination_record.id}"
      )

      nhs_id = vaccination_record.nhs_immunisations_api_id
      response, duration =
        execute_and_time do
          NHS::API.connection.put(
            "/immunisation-fhir-api/FHIR/R4/Immunization/#{nhs_id}",
            vaccination_record.fhir_record.to_json,
            {
              "Content-Type" => "application/fhir+json",
              "E-Tag" => vaccination_record.nhs_immunisations_api_etag
            }
          )
        end

      Rails.logger.info(
        "Update response returned with status #{response.status} in #{duration}s"
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

    def delete_immunisation(vaccination_record)
      unless Flipper.enabled?(:imms_api_integration)
        Rails.logger.info(
          "Not deleting vaccination record from immunisations API as the" \
            " feature flag is disabled: #{vaccination_record.id}"
        )
        return
      end

      if vaccination_record.nhs_immunisations_api_id.blank?
        raise "Vaccination record #{vaccination_record.id} missing NHS Immunisation ID"
      end

      Rails.logger.info(
        "Deleting vaccination record from immunisations API:" \
          " #{vaccination_record.id}"
      )

      nhs_id = vaccination_record.nhs_immunisations_api_id
      response, duration =
        execute_and_time do
          NHS::API.connection.delete(
            "/immunisation-fhir-api/FHIR/R4/Immunization/#{nhs_id}",
            nil,
            {
              "Accept" => "application/fhir+json",
              "E-Tag" => vaccination_record.nhs_immunisations_api_etag
            }
          )
        end

      Rails.logger.info(
        "Delete response returned with status #{response.status} in #{duration}s"
      )

      if response.status == 204
        # It's not entirely clear if the e-tag should be changed here, but
        # experiments show (by deletind and then re-creating a vaccination
        # record with an "update") that it appears that the e-tag is incremented
        # on the reviving update.
        vaccination_record.update!(
          nhs_immunisations_api_synced_at: Time.current
        )
      else
        raise "Error deleting vaccination record #{vaccination_record.id} from" \
                " Immunisations API: unexpected response status" \
                " #{response.status}"
      end
    rescue Faraday::ClientError => e
      if (diagnostics = extract_error_diagnostics(e&.response)).present?
        raise "Error deleting vaccination record #{vaccination_record.id} from" \
                " Immunisations API: #{diagnostics}"
      else
        raise
      end
    end

    def should_be_in_immunisations_api?(
      vaccination_record,
      ignore_nhs_number: false
    )
      vaccination_record.kept? && vaccination_record.recorded_in_service? &&
        vaccination_record.administered? &&
        vaccination_record.programme.can_sync_to_immunisations_api? &&
        (ignore_nhs_number || vaccination_record.patient.nhs_number.present?) &&
        vaccination_record.notify_parents &&
        vaccination_record.patient.not_invalidated?
    end

    def search_immunisations(patient, programmes:, date_from: nil, date_to: nil)
      unless Flipper.enabled?(:imms_api_integration)
        Rails.logger.info(
          "Not searching for vaccination records in the immunisations API as the" \
            "feature flag is disabled: Patient #{patient.id}"
        )
        return
      end

      if programmes.empty?
        raise "Cannot search for vaccination records in the immunisations API; no programmes provided."
      elsif !programmes.all?(&:can_search_in_immunisations_api?)
        raise "Cannot search for vaccination records in the immunisations API; one or more programmes is not supported."
      end

      Rails.logger.info(
        "Searching for vaccination records in immunisations API for patient: #{patient.id}"
      )

      params = {
        "patient.identifier" =>
          "https://fhir.nhs.uk/Id/nhs-number|#{patient.nhs_number}",
        "-immunization.target" =>
          programmes.map(&:snomed_target_disease_name).join(","),
        "-date.from" => date_from&.strftime("%F"),
        "-date.to" => date_to&.strftime("%F")
      }.compact

      response, duration =
        execute_and_time do
          NHS::API.connection.get(
            "/immunisation-fhir-api/FHIR/R4/Immunization",
            params,
            "Content-Type" => "application/fhir+json"
          )
        end

      Rails.logger.info(
        "Search response returned with status #{response.status} in #{duration}s"
      )

      if response.status == 200
        # # To create fixtures for testing
        # File.write("tmp/search_response.json", response.body.to_json)
        # Rails.logger.debug "Successfully saved"

        bundle = FHIR.from_contents(response.body.to_json)

        check_bundle_link_params(bundle, params)
        check_operation_outcome_entry(bundle)

        bundle
      else
        raise "Error searching for vaccination records for patient #{patient.id} in" \
                " Immunisations API: unexpected response status" \
                " #{response.status}"
      end
    rescue Faraday::ClientError => e
      if (diagnostics = extract_error_diagnostics(e&.response)).present?
        raise "Error searching for vaccination records for patient #{patient.id} in" \
                " Immunisations API: #{diagnostics}"
      else
        raise
      end
    end

    private

    def next_sync_action(vaccination_record)
      sync_pending_at = vaccination_record.nhs_immunisations_api_sync_pending_at
      if sync_pending_at.nil?
        raise "Cannot sync vaccination record #{vaccination_record.id}:" \
                " nhs_immunisations_api_sync_pending_at is nil"
      end

      should_be_recorded = should_be_in_immunisations_api?(vaccination_record)
      is_recorded = is_recorded_in_immunisations_api?(vaccination_record)

      if is_recorded
        last_synced_at = vaccination_record.nhs_immunisations_api_synced_at
        if last_synced_at.nil?
          raise "Cannot sync vaccination record #{vaccination_record.id}:" \
                  " nhs_immunisations_api_synced_at is nil"
        end

        return nil if last_synced_at >= sync_pending_at

        if should_be_recorded
          :update
        else
          discarded_at = vaccination_record.discarded_at
          :delete if discarded_at.nil? || last_synced_at < discarded_at
        end
      elsif should_be_recorded
        :create
      end
    end

    def is_recorded_in_immunisations_api?(vaccination_record)
      vaccination_record.nhs_immunisations_api_id.present?
    end

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
        raise "Patient nhs number is missing: #{vaccination_record.id}"
      end
    end

    def check_bundle_link_params(bundle, request_params)
      link = bundle.link&.find { it.relation == "self" }&.url

      uri = URI(link)
      bundle_params = URI.decode_www_form(uri.query).to_h

      # TODO: There is currently a bug in the API where the `Bundle.link` value for `-immunization.target` is
      #       incorrectly returned as `immunization.target` rather than `-immunization.target`. Matt Jarvis has
      #       told me that this should be fixed in their next release (3) or possibly release 4, at which point we
      #       can remove this logic.
      tweaked_bundle_params =
        bundle_params.transform_keys do |key|
          key == "immunization.target" ? "-immunization.target" : key
        end

      unless tweaked_bundle_params == request_params ||
               bundle_params == request_params
        raise NHS::ImmunisationsAPI::BundleLinkParamsMismatch,
              "Bundle link parameters do not match request parameters: #{tweaked_bundle_params} != #{request_params}"
      end
    end

    def check_operation_outcome_entry(bundle)
      operation_outcome_entry =
        bundle.entry&.find { it.resource.resourceType == "OperationOutcome" }

      if operation_outcome_entry.present?
        raise NHS::ImmunisationsAPI::OperationOutcomeInBundle,
              "OperationOutcome entry found in bundle: #{operation_outcome_entry.resource}"
      end
    end

    def execute_and_time(&block)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = block.call
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      [result, duration]
    end
  end
end
