# frozen_string_literal: true

class ProcessPatientChangesetsJob < ApplicationJob
  include PDSAPIThrottlingConcern

  queue_as :imports

  def perform(patient_changeset)
    attrs = patient_changeset.child_attributes

    if attrs["nhs_number"].blank? &&
         (pds_patient = search_for_patient(attrs)).present?
      attrs["nhs_number"] = pds_patient.nhs_number
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

  def search_for_patient(attrs)
    return nil if attrs["address_postcode"].blank?
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
