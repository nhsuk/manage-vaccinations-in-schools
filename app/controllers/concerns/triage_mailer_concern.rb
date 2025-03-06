# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient_session, consent)
    session = patient_session.session
    patient = patient_session.patient

    return unless patient.send_notifications?
    return if consent.via_self_consent?

    params = { consent:, session:, sent_by: current_user }

    if vaccination_will_happen?(patient_session, consent)
      EmailDeliveryJob.perform_later(:triage_vaccination_will_happen, **params)
    elsif vaccination_wont_happen?(patient_session, consent)
      EmailDeliveryJob.perform_later(:triage_vaccination_wont_happen, **params)
    elsif vaccination_at_clinic?(patient_session, consent)
      EmailDeliveryJob.perform_later(:triage_vaccination_at_clinic, **params)
    elsif consent.triage_needed?
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

  private

  def vaccination_will_happen?(patient_session, consent)
    programme = consent.programme
    consent.triage_needed? &&
      patient_session.triage.status[programme] ==
        PatientSession::Triage::SAFE_TO_VACCINATE
  end

  def vaccination_wont_happen?(patient_session, consent)
    programme = consent.programme
    consent.triage_needed? &&
      patient_session.triage.status[programme] ==
        PatientSession::Triage::DO_NOT_VACCINATE
  end

  def vaccination_at_clinic?(patient_session, consent)
    programme = consent.programme
    consent.triage_needed? &&
      patient_session.triage.status[programme] ==
        PatientSession::Triage::DELAY_VACCINATION
  end
end
