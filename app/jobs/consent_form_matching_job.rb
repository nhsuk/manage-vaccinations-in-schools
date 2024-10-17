# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  include NHSNumberLookupConcern

  queue_as :consents

  def perform(consent_form)
    patient = find_patient(consent_form)
    return unless patient

    consent_form.match_with_patient!(patient)
  end

  def find_patient(consent_form)
    nhs_number = find_nhs_number(consent_form)

    # Search globally if we have an NHS number
    if nhs_number && (patient = Patient.find_by(nhs_number:))
      return patient
    end

    # Search in the scheduled session if not
    session = consent_form.scheduled_session

    patients =
      session.patients.match_existing(
        nhs_number: nil,
        given_name: consent_form.given_name,
        family_name: consent_form.family_name,
        date_of_birth: consent_form.date_of_birth,
        address_postcode: consent_form.address_postcode
      )

    patients.first if patients.count == 1
  end
end
