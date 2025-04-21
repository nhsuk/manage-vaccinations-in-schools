# frozen_string_literal: true

class PatientNHSNumberLookupWithPendingChangesJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :imports

  def perform(patient)
    patient_with_pending_changes = patient.with_pending_changes
    patient_with_pending_changes.nhs_number =
      nil unless patient.nhs_number_changed?

    return unless patient_with_pending_changes.changed?

    if patient_with_pending_changes.nhs_number.present? &&
         !patient_with_pending_changes.invalidated?
      return
    end

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
  end
end
