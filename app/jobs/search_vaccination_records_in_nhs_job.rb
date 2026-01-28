# frozen_string_literal: true

class SearchVaccinationRecordsInNHSJob < ImmunisationsAPIJob
  sidekiq_options queue: :immunisations_api_search

  def perform(patient_id)
    begin
      patient = Patient.includes(teams: :organisation).find(patient_id)
    rescue ActiveRecord::RecordNotFound
      # This patient has since been merged with another so we don't need to
      # perform a search.
      return
    end

    tx_id = SecureRandom.urlsafe_base64(16)

    SemanticLogger.tagged(tx_id:, job_id:) do
      Sentry.set_tags(tx_id:, job_id:)

      programmes = Programme.all_as_variants

      feature_flag_enabled =
        programmes.any? do |programme|
          Flipper.enabled?(:imms_api_search_job, programme)
        end
      return unless feature_flag_enabled

      if patient.nhs_number.nil?
        incoming_vaccination_records = []
      else
        fhir_bundle =
          NHS::ImmunisationsAPI.search_immunisations(patient, programmes:)

        incoming_vaccination_records =
          extract_vaccination_records(fhir_bundle).map do |fhir_record|
            FHIRMapper::VaccinationRecord.from_fhir_record(
              fhir_record,
              patient:
            )
          end

        incoming_vaccination_records =
          deduplicate_vaccination_records(patient, incoming_vaccination_records)

        incoming_vaccination_records =
          select_programme_feature_flagged_records(incoming_vaccination_records)
      end

      existing_vaccination_records =
        patient
          .vaccination_records
          .includes(:identity_check)
          .sourced_from_nhs_immunisations_api
          .for_programmes(programmes)

      existing_vaccination_records.find_each do |vaccination_record|
        incoming_vaccination_record =
          incoming_vaccination_records.find do
            it.nhs_immunisations_api_id ==
              vaccination_record.nhs_immunisations_api_id
          end

        if incoming_vaccination_record
          vaccination_record.update!(
            incoming_vaccination_record
              .attributes
              .except("id", "uuid", "created_at")
              .merge(updated_at: Time.current)
          )

          incoming_vaccination_records.delete(incoming_vaccination_record)
        else
          vaccination_record.destroy!
        end
      end

      # Remaining incoming_vaccination_records are new
      incoming_vaccination_records.each do |vaccination_record|
        vaccination_record.save!
        AlreadyHadNotificationSender.call(vaccination_record:)
      end

      StatusUpdater.call(patient:)
    end
  end

  private

  def select_programme_feature_flagged_records(vaccination_records)
    vaccination_records.select do
      Flipper.enabled?(:imms_api_search_job, it.programme)
    end
  end

  def extract_vaccination_records(fhir_bundle)
    fhir_bundle
      .entry
      .map { it.resource if it.resource.resourceType == "Immunization" }
      .compact
  end

  def deduplicate_vaccination_records(patient, incoming_vaccination_records)
    vaccination_records =
      incoming_vaccination_records +
        patient.vaccination_records.sourced_from_service.includes(:team)

    grouped_vaccination_records =
      vaccination_records.group_by { [it.performed_at_date, it.programme_type] }

    deduplicated_vaccination_records = []

    grouped_vaccination_records.each_value do |records|
      deduplicated_vaccination_records +=
        if records.any?(&:sourced_from_service?)
          # If there exists a Mavis record, discard all incoming records
          []
        elsif records.none?(&:nhs_immunisations_api_primary_source)
          # If no records are primary sources, keep all of them
          records
        else
          # Otherwise prefer primary sources
          records.select(&:nhs_immunisations_api_primary_source)
        end
    end

    deduplicated_vaccination_records.select(
      &:sourced_from_nhs_immunisations_api?
    )
  end
end
