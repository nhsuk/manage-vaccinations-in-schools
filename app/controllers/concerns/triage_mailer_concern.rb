# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient_session, consent)
    session = patient_session.session
    patient = patient_session.patient

    return unless patient.send_notifications?

    params = { consent:, session:, sent_by: current_user }

    if vaccination_will_happen?(patient_session, consent)
      TriageMailer.with(params).vaccination_will_happen.deliver_later
    elsif vaccination_wont_happen?(patient_session, consent)
      TriageMailer.with(params).vaccination_wont_happen.deliver_later
    elsif vaccination_at_clinic?(patient_session, consent)
      TriageMailer.with(params).vaccination_at_clinic.deliver_later
    elsif consent.triage_needed?
      ConsentMailer.with(params).confirmation_triage.deliver_later
    elsif consent.response_refused?
      ConsentMailer.with(params).confirmation_refused.deliver_later
      TextDeliveryJob.perform_later(:consent_confirmation_refused, **params)
    else
      ConsentMailer.with(params).confirmation_given.deliver_later
      TextDeliveryJob.perform_later(:consent_confirmation_given, **params)
    end
  end

  private

  def vaccination_will_happen?(patient_session, consent)
    consent.triage_needed? && patient_session.triaged_ready_to_vaccinate?
  end

  def vaccination_wont_happen?(patient_session, consent)
    consent.triage_needed? && patient_session.triaged_do_not_vaccinate?
  end

  def vaccination_at_clinic?(patient_session, consent)
    consent.triage_needed? && patient_session.delay_vaccination?
  end
end
