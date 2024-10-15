# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  queue_as :default

  def perform(consent_form)
    session = consent_form.scheduled_session

    patients =
      session.patients.match_existing(
        nhs_number: nil,
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
