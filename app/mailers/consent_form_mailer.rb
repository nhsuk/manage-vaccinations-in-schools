# frozen_string_literal: true

class ConsentFormMailer < ApplicationMailer
  def confirmation(consent_form: nil, consent: nil, session: nil)
    app_template_mail(
      :parental_consent_confirmation,
      consent_form,
      consent,
      session
    )
  end

  def confirmation_needs_triage(consent_form: nil, consent: nil, session: nil)
    app_template_mail(
      :parental_consent_confirmation_needs_triage,
      consent_form,
      consent,
      session
    )
  end

  def confirmation_injection(consent_form: nil, consent: nil, session: nil)
    app_template_mail(
      :parental_consent_confirmation_injection,
      consent_form,
      consent,
      session
    )
  end

  def confirmation_refused(consent_form: nil, consent: nil, session: nil)
    app_template_mail(
      :parental_consent_confirmation_refused,
      consent_form,
      consent,
      session
    )
  end

  def give_feedback(consent_form: nil, consent: nil, session: nil)
    app_template_mail(
      :parental_consent_give_feedback,
      consent_form,
      consent,
      session
    )
  end

  private

  def opts(consent_form, consent, session = nil)
    @consent_form = consent_form
    @consent = consent

    patient = consent_form || consent.patient
    parent = consent_form || consent.parent

    super(session || consent_form.session, patient, parent)
  end

  def personalisation
    super.merge(reason_for_refusal:, survey_deadline_date:)
  end

  def reason_for_refusal
    reason = @consent_form&.reason || @consent&.reason_for_refusal
    I18n.t("mailers.consent_form_mailer.reasons_for_refusal.#{reason}")
  end

  def survey_deadline_date
    recorded_at = @consent_form&.recorded_at || @consent.recorded_at

    (recorded_at + 7.days).to_date.to_fs(:long)
  end
end
