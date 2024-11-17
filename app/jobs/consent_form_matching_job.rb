# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :consents

  def perform(consent_form)
    @consent_form = consent_form

    # Match if we find a patient with the PDS NHS number
    return if match_with_exact_nhs_number

    # Look for patients in the original session with no NHS number
    if session_patients.count == 1
      # If we found exactly one, match the consent form to this patient
      match_patient(session_patients.first)
    end

    # Look for patients in any session with matching details
    if pds_patient && matching_patients.empty?
      # If no patients are found, store the PDS NHS number in the consent form.
      # A nurse may then create a patient record and we can try this job again
      update_consent_form_nhs_number
    end

    # If we found:
    # - No patients with the NHS number from the PDS record
    # - 2 or more patients in the original session, matching with no NHS number
    # - 1 or more patients in any session, matching with no NHS number
    # Then do nothing; the nurse needs to match manually or create a new patient
  end

  private

  def query
    {
      given_name: @consent_form.given_name,
      family_name: @consent_form.family_name,
      date_of_birth: @consent_form.date_of_birth,
      address_postcode: @consent_form.address_postcode
    }
  end

  def pds_patient
    @pds_patient ||= PDS::Patient.search(**query)
  end

  def match_with_exact_nhs_number
    return false unless pds_patient

    patient = Patient.find_by(nhs_number: pds_patient.nhs_number)
    return false unless patient

    patient.update_from_pds!(pds_patient)
    @consent_form.match_with_patient!(patient)
  end

  def session_patients
    @session_patients ||=
      @consent_form.original_session.patients.match_existing(
        nhs_number: nil,
        **query
      )
  end

  def matching_patients
    @matching_patients ||= Patient.match_existing(nhs_number: nil, **query)
  end

  def update_consent_form_nhs_number
    @consent_form.update!(nhs_number: pds_patient.nhs_number)
  end

  def match_patient(patient)
    if pds_patient
      if patient.nhs_number.nil?
        # TODO: Can we take this opportunity to set the NHS number on the patient?
      elsif patient.nhs_number != pds_patient.nhs_number
        # We found a patient in PDS and we found one in Mavis using the same search
        # query, but the NHS numbers don't match.
        raise Patient::NHSNumberMismatch
      end
    end

    @consent_form.match_with_patient!(patient)
  end
end
