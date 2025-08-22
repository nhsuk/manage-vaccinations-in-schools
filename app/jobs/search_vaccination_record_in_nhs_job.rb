# frozen_string_literal: true

class SearchVaccinationRecordInNHSJob < ApplicationJob
  def self.concurrent_jobs_per_second = 2
  def self.concurrency_key = :immunisations_api

  include ImmunisationsAPIThrottlingConcern

  queue_as :immunisation_api # TODO: Does this need to be changed?

  def perform(patient)
    tx_id = SecureRandom.urlsafe_base64(16)
    SemanticLogger.tagged(tx_id:, job_id: provider_job_id || job_id) do
      Sentry.set_tags(tx_id:, job_id: provider_job_id || job_id)

      programmes = Programme.where(type: Programme::SEARCH_PROGRAMME_TYPES)

      fhir_bundle = NHS::ImmunisationsAPI.search_immunisations(patient, programmes:)

      vaccination_records = extract_vaccination_records(fhir_bundle).map do |fhir_record|
        # TODO: Add team to `from_fhir_record` call somehow
        FHIRMapper::VaccinationRecord.from_fhir_record(fhir_record, patient:)
      end

      existing_vaccination_records = patient.vaccination_records.where(programme: programmes) # TODO: , source: :nhs_immunisations_api)

      # TODO: implement idempotent acceptance of vaccination records
    end
  end

  def extract_vaccination_records(fhir_bundle)
    fhir_bundle.entry.map { |entry|
      entry.resource if entry.resource.resourceType == "Immunization"
    }.compact
  end

  def extract_patient(fhir_bundle)
    fhir_bundle.entry.find { |entry| entry.resource.resourceType == "Patient" }&.resource
  end
end
