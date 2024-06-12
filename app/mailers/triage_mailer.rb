class TriageMailer < ApplicationMailer
  def vaccination_will_happen(patient_session, consent)
    @patient_session = patient_session
    @consent = consent

    template_mail(
      EMAILS[:triage_vaccination_will_happen],
      **opts(patient_session)
    )
  end

  def vaccination_wont_happen(patient_session, consent)
    @patient_session = patient_session
    @consent = consent

    template_mail(
      EMAILS[:triage_vaccination_wont_happen],
      **opts(patient_session)
    )
  end

  private

  def to
    @consent.parent.email
  end

  def parent_name
    @consent.parent.name
  end
end
