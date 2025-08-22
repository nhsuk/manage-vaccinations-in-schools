# frozen_string_literal: true

class SearchVaccinationRecordsInNHSJob < ApplicationJob
  def self.concurrent_jobs_per_second = 2
  def self.concurrency_key = :immunisations_api

  include ImmunisationsAPIThrottlingConcern

  queue_as :immunisation_api # TODO: Does this need to be changed?

  def perform(patient)
    tx_id = SecureRandom.urlsafe_base64(16)
    SemanticLogger.tagged(tx_id:, job_id: provider_job_id || job_id) do
      Sentry.set_tags(tx_id:, job_id: provider_job_id || job_id)

      # TODO: check feature flags?

      programmes = Programme.where(type: Programme::SEARCH_PROGRAMME_TYPES)

      fhir_bundle =
        NHS::ImmunisationsAPI.search_immunisations(patient, programmes:)

      incoming_vaccination_records =
        extract_vaccination_records(fhir_bundle).map do |fhir_record|
          next if fhir_record.identifier.system == FHIRMapper::VaccinationRecord::MAVIS_SYSTEM_NAME

          FHIRMapper::VaccinationRecord.from_fhir_record(
            fhir_record,
            patient:,
            team: patient.school.team
          )
        end
      existing_vaccination_records =
        patient.vaccination_records.where(
          programme: programmes,
          source: :nhs_immunisations_api
        )

      existing_vaccination_records.find_each do |vaccination_record|
        incoming_vaccination_record =
          incoming_vaccination_records.find do
            it.uuid == vaccination_record.uuid
          end

        if incoming_vaccination_record
          vaccination_record.update!(
            incoming_vaccination_record.attributes.except("id", "created_at")
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

  def extract_patient(fhir_bundle)
    fhir_bundle.entry.find { it.resource.resourceType == "Patient" }&.resource
  end
end
