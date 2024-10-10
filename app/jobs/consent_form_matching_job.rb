# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  queue_as :default

  def perform(consent_form)
    session = consent_form.scheduled_session

    patients =
      session.patients.match_existing(
        nhs_number: nil,
        first_name: consent_form.first_name,
        last_name: consent_form.last_name,
        date_of_birth: consent_form.date_of_birth,
        address_postcode: consent_form.address_postcode
      )

    return if patients.count != 1

    consent_form.match_with_patient_session!(
      PatientSession.find_by!(patient: patients.first, session:)
    )
  end
end
