# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  include NHSNumberLookupConcern

  queue_as :consents

  def perform(consent_form)
    session = consent_form.scheduled_session

    nhs_number = find_nhs_number(consent_form)

    # TODO: What happens if we find an NHS number for a patient,
    # TODO: but they're not in the session?

    patients =
      session.patients.match_existing(
        nhs_number:,
        given_name: consent_form.given_name,
        family_name: consent_form.family_name,
        date_of_birth: consent_form.date_of_birth,
        address_postcode: consent_form.address_postcode
      )

    return if patients.count != 1

    consent_form.match_with_patient_session!(
      PatientSession.find_by!(patient: patients.first, session:)
    )
  end
end
