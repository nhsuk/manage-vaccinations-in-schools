# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_mail(patient_session, consent)
    session = patient_session.session

    if send_vaccination_will_happen_email?(patient_session, consent)
      TriageMailer.vaccination_will_happen(
        patient_session,
        consent
      ).deliver_later
    elsif send_vaccination_wont_happen_email?(patient_session, consent)
      TriageMailer.vaccination_wont_happen(
        patient_session,
        consent
      ).deliver_later
    elsif consent.response_refused?
      ConsentFormMailer.confirmation_refused(consent:, session:).deliver_later
    elsif consent.triage_needed?
      ConsentFormMailer.confirmation_needs_triage(
        consent:,
        session:
      ).deliver_later
    else
      ConsentFormMailer.confirmation(consent:, session:).deliver_later
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
