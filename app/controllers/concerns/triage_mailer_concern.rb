# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient_session, consent, triage)
    session = patient_session.session
    patient = patient_session.patient

    return unless patient.send_notifications?
    return if consent.via_self_consent?

    if triage && consent.programme_id != triage.programme_id
      raise "Consent and triage programmes don't match."
    end

    params = { consent:, session:, sent_by: current_user, triage: }.compact

    if consent.requires_triage? && triage&.ready_to_vaccinate?
      EmailDeliveryJob.perform_later(:triage_vaccination_will_happen, **params)
    elsif consent.requires_triage? && triage&.do_not_vaccinate?
      EmailDeliveryJob.perform_later(:triage_vaccination_wont_happen, **params)
    elsif consent.requires_triage? && triage&.delay_vaccination?
      EmailDeliveryJob.perform_later(:triage_vaccination_at_clinic, **params)
    elsif consent.requires_triage?
      EmailDeliveryJob.perform_later(:consent_confirmation_triage, **params)
    elsif consent.response_refused?
      EmailDeliveryJob.perform_later(:consent_confirmation_refused, **params)

      if consent.parent.phone_receive_updates
        SMSDeliveryJob.perform_later(:consent_confirmation_refused, **params)
      end
    elsif consent.response_given?
      EmailDeliveryJob.perform_later(:consent_confirmation_given, **params)

      if consent.parent.phone_receive_updates
        SMSDeliveryJob.perform_later(:consent_confirmation_given, **params)
      end
    end
  end
end
