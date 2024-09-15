# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_mail(patient_session, consent)
    session = patient_session.session

    if send_vaccination_will_happen_email?(patient_session, consent)
      TriageMailer
        .with(consent:, session:)
        .vaccination_will_happen
        .deliver_later
    elsif send_vaccination_wont_happen_email?(patient_session, consent)
      TriageMailer
        .with(consent:, session:)
        .vaccination_wont_happen
        .deliver_later
    elsif consent.response_refused?
      ConsentMailer.with(consent:, session:).confirmation_refused.deliver_later
    elsif consent.triage_needed?
      ConsentMailer
        .with(consent:, session:)
        .confirmation_needs_triage
        .deliver_later
    else
      ConsentMailer.with(consent:, session:).confirmation.deliver_later
    end
  end

  def send_vaccination_will_happen_email?(patient_session, consent)
    consent.triage_needed? && patient_session.triaged_ready_to_vaccinate?
  end

  def send_vaccination_wont_happen_email?(patient_session, consent)
    consent.triage_needed? &&
      (
        patient_session.triaged_do_not_vaccinate? ||
          patient_session.delay_vaccination?
      )
  end
end
