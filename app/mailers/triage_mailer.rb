# frozen_string_literal: true

class TriageMailer < ApplicationMailer
  def vaccination_will_happen(patient_session, consent)
    @patient_session = patient_session
    @consent = consent

    app_template_mail(
      :triage_vaccination_will_happen,
      patient_session.session,
      patient_session.patient,
      consent.parent
    )
  end

  def vaccination_wont_happen(patient_session, consent)
    @patient_session = patient_session
    @consent = consent

    app_template_mail(
      :triage_vaccination_wont_happen,
      patient_session.session,
      patient_session.patient,
      consent.parent
    )
  end
end
