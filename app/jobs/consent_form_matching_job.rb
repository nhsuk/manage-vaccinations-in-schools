# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  queue_as :default

  def perform(consent_form)
    patient = consent_form.find_matching_patient

    return unless patient

    patient_session = consent_form.session.patient_sessions.find_by!(patient:)

    Consent.from_consent_form!(consent_form, patient_session)
  end
end
