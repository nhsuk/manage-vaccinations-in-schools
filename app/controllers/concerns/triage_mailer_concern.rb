# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient_session, consent)
    session = patient_session.session
    patient = patient_session.patient

    return unless patient.send_notifications?

    if vaccination_will_happen?(patient_session, consent)
      TriageMailer
        .with(consent:, session:)
        .vaccination_will_happen
        .deliver_later
    elsif vaccination_wont_happen?(patient_session, consent)
      TriageMailer
        .with(consent:, session:)
        .vaccination_wont_happen
        .deliver_later
    elsif consent.response_refused?
      ConsentMailer.with(consent:, session:).confirmation_refused.deliver_later
      TextDeliveryJob.perform_later(:consent_refused, consent:, session:)
    elsif consent.triage_needed?
      ConsentMailer
        .with(consent:, session:)
        .confirmation_needs_triage
        .deliver_later
    else
      ConsentMailer.with(consent:, session:).confirmation.deliver_later
      TextDeliveryJob.perform_later(:consent_given, consent:, session:)
    end
  end

  private

  def vaccination_will_happen?(patient_session, consent)
    consent.triage_needed? && patient_session.triaged_ready_to_vaccinate?
  end

  def vaccination_wont_happen?(patient_session, consent)
    consent.triage_needed? &&
      (
        patient_session.triaged_do_not_vaccinate? ||
          patient_session.delay_vaccination?
      )
  end
end
