# frozen_string_literal: true

class TriageMailer < ApplicationMailer
  def vaccination_will_happen(patient_session, consent)
    @patient_session = patient_session
    @consent = consent
    @parent = consent.parent

    template_mail(
      EMAILS[:triage_vaccination_will_happen],
      **opts(patient_session, @parent)
    )
  end

  def vaccination_wont_happen(patient_session, consent)
    @patient_session = patient_session
    @consent = consent
    @parent = consent.parent

    template_mail(
      EMAILS[:triage_vaccination_wont_happen],
      **opts(patient_session, @parent)
    )
  end
end
