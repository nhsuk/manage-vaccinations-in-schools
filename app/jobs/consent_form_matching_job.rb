# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :consents

  def perform(consent_form)
    query = {
      given_name: consent_form.given_name,
      family_name: consent_form.family_name,
      date_of_birth: consent_form.date_of_birth,
      address_postcode: consent_form.address_postcode
    }

    pds_patient = PDS::Patient.search(**query)

    # Search globally if we have an NHS number
    if pds_patient &&
         (patient = Patient.find_by(nhs_number: pds_patient.nhs_number))
      patient.update_from_pds!(pds_patient)
      consent_form.match_with_patient!(patient)
      return
    end

    # Search in the original scheduled session if not
    session = consent_form.original_session

    patients = session.patients.match_existing(nhs_number: nil, **query)

    return if patients.count != 1

    patient = patients.first

    if pds_patient
      if patient.nhs_number.nil?
        # TODO: Can we take this opportunity to set the NHS number on the patient?
      elsif patient.nhs_number != pds_patient.nhs_number
        # We found a patient in PDS and we found one in Mavis using the same search
        # query, but the NHS numbers don't match.
        raise Patient::NHSNumberMismatch
      end
    end

    consent_form.match_with_patient!(patient)
  end
end
