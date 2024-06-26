# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  queue_as :default

  def perform(consent_form_id)
    consent_form = ConsentForm.find(consent_form_id)

    matching_patient = consent_form.find_matching_patient

    if matching_patient
      patient_session =
        consent_form.session.patient_sessions.find_by(patient: matching_patient)
      Consent.from_consent_form!(consent_form, patient_session)
    end
  end
end
