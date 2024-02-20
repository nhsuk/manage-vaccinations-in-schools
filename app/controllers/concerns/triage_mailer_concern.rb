module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_mail(patient_session)
    if patient_session.triaged_ready_to_vaccinate?
      TriageMailer.vaccination_will_happen(patient_session).deliver_later
    elsif patient_session.triaged_do_not_vaccinate? ||
          patient_session.delay_vaccination?
      TriageMailer.vaccination_wont_happen(patient_session).deliver_later
    end
  end
end
