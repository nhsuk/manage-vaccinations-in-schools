# frozen_string_literal: true

class SearchVaccinationRecordsInNHSJob < ImmunisationsAPIJob
  def perform(patient_id)
    patient = Patient.find(patient_id)

    tx_id = SecureRandom.urlsafe_base64(16)

    SemanticLogger.tagged(tx_id:, job_id:) do
      Sentry.set_tags(tx_id:, job_id:)

      return unless Flipper.enabled?(:imms_api_search_job)

      programmes = Programme.can_search_in_immunisations_api

      if patient.nhs_number.nil?
        incoming_vaccination_records = []
      else
        fhir_bundle =
          NHS::ImmunisationsAPI.search_immunisations(patient, programmes:)

        incoming_vaccination_records =
          extract_vaccination_records(fhir_bundle).map do |fhir_record|
            if FHIRMapper::VaccinationRecord::MAVIS_SYSTEM_NAME.in?(
                 fhir_record.identifier.map(&:system)
               )
              next
            end

            FHIRMapper::VaccinationRecord.from_fhir_record(
              fhir_record,
              patient:
            )
          end
        incoming_vaccination_records = incoming_vaccination_records.compact
      end

      existing_vaccination_records =
        patient
          .vaccination_records
          .includes(:identity_check)
          .where(programme: programmes, source: :nhs_immunisations_api)

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
      incoming_vaccination_records.each(&:save!)
    end
  end

  def extract_vaccination_records(fhir_bundle)
    fhir_bundle
      .entry
      .map { it.resource if it.resource.resourceType == "Immunization" }
      .compact
  end
end
