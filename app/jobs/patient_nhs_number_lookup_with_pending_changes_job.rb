# frozen_string_literal: true

class PatientNHSNumberLookupWithPendingChangesJob < ApplicationJob
  include PDSAPIThrottlingConcern

  queue_as :pds

  def perform(patient)
    patient_with_pending_changes = patient.with_pending_changes

    # If pending changes included an NHS number explicitly (and the patient
    # isn't invalid) then we don't need to look up what their new NHS number
    # might be.
    if patient_with_pending_changes.nhs_number_changed? &&
         patient_with_pending_changes.nhs_number.present? &&
         !patient_with_pending_changes.invalidated?
      return
    end

    # If applying pending changes doesn't change the patient then their NHS
    # number won't have changed either so we don't need to look them up.
    return unless patient_with_pending_changes.changed?

    pds_patient =
      PDS::Patient.search(
        family_name: patient_with_pending_changes.family_name,
        given_name: patient_with_pending_changes.given_name,
        date_of_birth: patient_with_pending_changes.date_of_birth,
        address_postcode: patient_with_pending_changes.address_postcode
      )

    return if pds_patient.nil?

    patient.stage_changes(
      nhs_number: pds_patient.nhs_number,
      invalidated_at: nil
    )
    patient.save!
  end
end
