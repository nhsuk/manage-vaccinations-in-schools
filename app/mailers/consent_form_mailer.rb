class ConsentFormMailer < ApplicationMailer
  def confirmation(consent_form)
    template_mail("7cda7ae5-99a2-4c40-9a3e-1863e23f7a73", **opts(consent_form))
  end

  def confirmation_needs_triage(consent_form)
    template_mail("604ee667-c996-471e-b986-79ab98d0767c", **opts(consent_form))
  end

  def confirmation_injection(consent_form)
    template_mail("4d09483a-8181-4acb-8ba3-7abd6c8644cd", **opts(consent_form))
  end

  def confirmation_refused(consent_form)
    template_mail("5a676dac-3385-49e4-98c2-fc6b45b5a851", **opts(consent_form))
  end

  private

  def opts(consent_form)
    @consent_form = consent_form

    { to:, reply_to_id:, personalisation: }
  end

  def to
    @consent_form.parent_email
  end

  def reply_to_id
    @consent_form.session.campaign.team.reply_to_id
  end

  def personalisation
    {
      full_and_preferred_patient_name:,
      location_name:,
      long_date:,
      observed_session:,
      parent_name:,
      reason_for_refusal:,
      short_date:,
      short_patient_name:,
      short_patient_name_apos:,
      team_email:,
      team_phone:,
      vaccination:
    }
  end

  def full_and_preferred_patient_name
    if @consent_form.common_name.present?
      @consent_form.full_name + " (known as #{@consent_form.common_name})"
    else
      @consent_form.full_name
    end
  end

  def short_patient_name
    @consent_form.common_name.presence || @consent_form.first_name
  end

  def short_patient_name_apos
    apos = "'"
    apos += "s" unless short_patient_name.ends_with?("s")
    short_patient_name + apos
  end

  def observed_session
    @consent_form.session.location.permission_to_observe_required?
  end

  def location_name
    @consent_form.session.location.name
  end

  def short_date
    @consent_form.session.date.strftime("%-d %B")
  end

  def long_date
    @consent_form.session.date.strftime("%A %-d %B")
  end

  def parent_name
    @consent_form.parent_name
  end

  def reason_for_refusal
    I18n.t("consent_form_mailer.reasons_for_refusal.#{@consent_form.reason}")
  end

  def team_email
    I18n.t("service.email")
  end

  def team_phone
    I18n.t("service.temporary_cumbria_phone")
  end

  def vaccination
    "#{@consent_form.session.campaign.name} vaccination"
  end
end
