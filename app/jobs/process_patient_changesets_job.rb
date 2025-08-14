# frozen_string_literal: true

class ProcessPatientChangesetsJob < ApplicationJob
  def self.concurrent_jobs_per_second = 5
  def self.concurrency_key = :pds

  include NHSAPIConcurrencyConcern

  queue_as :pds

  def perform(patient_changeset)
    attrs = patient_changeset.child_attributes

    pds_patient =
      if attrs["nhs_number"].present?
        patient_found = find_patient(attrs["nhs_number"])

        if patient_found == :invalid
          search_for_patient(attrs).then do |newly_found_patient|
            # If we found a patient, update the changeset with the new NHS
            # number. If we couldn't determine who this patient should really
            # be, we won't have an NHS number to replace the invalid one, so
            # just mark it as invalid.
            patient_changeset.invalidate! if newly_found_patient.nil?
            newly_found_patient
          end
        elsif patient_found == :not_found
          patient_changeset.update!(nhs_number: nil)
          search_for_patient(attrs)
        else
          patient_found
        end
      else
        search_for_patient(attrs)
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
      if patient_changeset.import.slow?
        CommitPatientChangesetsJob.perform_later(patient_changeset.import)
      else
        CommitPatientChangesetsJob.perform_now(patient_changeset.import)
      end
    end
  end

  private

  def find_patient(nhs_number)
    PDS::Patient.find(nhs_number)
  rescue NHS::PDS::InvalidatedResource, NHS::PDS::InvalidNHSNumber
    :invalid
  rescue NHS::PDS::PatientNotFound
    :not_found
  end

  def search_for_patient(attrs)
    PDS::Patient.search(
      family_name: attrs["family_name"],
      given_name: attrs["given_name"],
      date_of_birth: attrs["date_of_birth"],
      address_postcode: attrs["address_postcode"]
    )
  rescue NHS::PDS::PatientNotFound, NHS::PDS::TooManyMatches
    nil
  end
end
