class ConsentFormMailer < ApplicationMailer
  def confirmation(consent_form: nil, consent: nil, session: nil)
    template_mail(
      EMAILS[:parental_consent_confirmation],
      **opts(consent_form:, consent:, session:)
    )
  end

  def confirmation_needs_triage(consent_form: nil, consent: nil, session: nil)
    template_mail(
      EMAILS[:parental_consent_confirmation_needs_triage],
      **opts(consent_form:, consent:, session:)
    )
  end

  def confirmation_injection(consent_form: nil, consent: nil, session: nil)
    template_mail(
      EMAILS[:parental_consent_confirmation_injection],
      **opts(consent_form:, consent:, session:)
    )
  end

  def confirmation_refused(consent_form: nil, consent: nil, session: nil)
    template_mail(
      EMAILS[:parental_consent_confirmation_refused],
      **opts(consent_form:, consent:, session:)
    )
  end

  def give_feedback(consent_form: nil, consent: nil, session: nil)
    template_mail(
      EMAILS[:parental_consent_give_feedback],
      **opts(consent_form:, consent:, session:)
    )
  end

  private

  def opts(consent_form:, consent:, session: nil)
    @consent_form = consent_form
    @consent = consent
    @patient = consent_form || consent.patient
    @session = session || consent_form.session

    { to:, reply_to_id:, personalisation: consent_form_personalisation }
  end

  def consent_form_personalisation
    personalisation.merge(reason_for_refusal:, survey_deadline_date:)
  end

  def reason_for_refusal
    reason = @consent_form&.reason || @consent&.reason_for_refusal
    I18n.t("mailers.consent_form_mailer.reasons_for_refusal.#{reason}")
  end

  def survey_deadline_date
    recorded_at = @consent_form&.recorded_at || @consent.recorded_at

    (recorded_at + 7.days).to_fs(:nhsuk_date)
  end
end
