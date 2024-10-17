# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  include NHSNumberLookupConcern

  queue_as :consents

  def perform(consent_form)
    nhs_number = find_nhs_number(consent_form)

    # Search globally if we have an NHS number
    if nhs_number && (patient = Patient.find_by(nhs_number:))
      consent_form.match_with_patient!(patient)
      return
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

    return if patients.count != 1

    patient = patients.first

    unless nhs_number.nil?
      if patient.nhs_number.nil?
        # TODO: Can we take this opportunity to set the NHS number on the patient?
      elsif patient.nhs_number != nhs_number
        # We found a patient in PDS and we found one in Mavis using the same search
        # query, but the NHS numbers don't match.
        raise PatientNHSNumberMismatch
      end
    end

    consent_form.match_with_patient!(patient)
  end

  class PatientNHSNumberMismatch < StandardError
  end
end
