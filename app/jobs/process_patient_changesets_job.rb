# frozen_string_literal: true

class ProcessPatientChangesetsJob < ApplicationJob
  def self.concurrent_jobs_per_second = 5
  def self.concurrency_key = :pds

  include NHSAPIConcurrencyConcern

  queue_as :pds

  def perform(patient_changeset)
    pds_patient =
      if patient_changeset.patient.nhs_number.nil?
        PDS::Patient.search(
          family_name: patient_changeset.family_name,
          given_name: patient_changeset.given_name,
          date_of_birth: patient_changeset.date_of_birth,
          address_postcode: patient_changeset.address_postcode
        )
      else
        PDS::Patient.find(patient_changeset.nhs_number)
      end

    if pds_patient.present?
      patient_changeset.pending_changes.tap do |changes|
        changes["pds"] = {
          nhs_number: pds_patient.nhs_number,
          restricted: pds_patient.restricted,
          gp_ods_code: pds_patient.gp_ods_code,
          date_of_death: pds_patient.date_of_death
        }
      end
    end

    patient_changeset.processed!
    patient_changeset.save!

    # TODO: Make this atomic
    if patient_changeset.import.changesets.pending.none?
      CommitPatientChangesetsJob.perform_later(patient_changeset.import)
    end
  rescue NHS::PDS::PatientNotFound
    patient_changeset.update!(nhs_number: nil)
    PatientNHSNumberLookupJob.perform_later(patient_changeset)
  rescue NHS::PDS::InvalidatedResource, NHS::PDS::InvalidNHSNumber
    patient_changeset.invalidate!
    PatientNHSNumberLookupJob.perform_later(patient_changeset)
  end
end
