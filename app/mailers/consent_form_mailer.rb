class ConsentFormMailer < ApplicationMailer
  def reply_to_id(consent_form:)
    consent_form.session.campaign.team.reply_to_id
  end

  def confirmation(consent_form)
    if consent_form.common_name.present?
      short_patient_name = consent_form.common_name
      full_and_preferred_patient_name =
        consent_form.full_name + " (known as #{consent_form.common_name})"
    else
      short_patient_name = consent_form.first_name
      full_and_preferred_patient_name = consent_form.full_name
    end
    apos = "'"
    apos += "s" unless short_patient_name.ends_with?("s")
    short_patient_name_apos = short_patient_name + apos
    observed_session =
      consent_form.session.location.permission_to_observe_required?

    template_mail(
      "7cda7ae5-99a2-4c40-9a3e-1863e23f7a73",
      to: consent_form.parent_email,
      reply_to_id: reply_to_id(consent_form:),
      personalisation: {
        short_date: consent_form.session.date.strftime("%-d %B"),
        parent_name: consent_form.parent_name,
        location_name: consent_form.session.location.name,
        long_date: consent_form.session.date.strftime("%A %-d %B"),
        full_and_preferred_patient_name:,
        short_patient_name:,
        short_patient_name_apos:,
        team_email: I18n.t("service.email"),
        team_phone: I18n.t("service.temporary_cumbria_phone"),
        observed_session:
      }
    )
  end

  def confirmation_needs_triage(consent_form)
    if consent_form.common_name.present?
      short_patient_name = consent_form.common_name
      full_and_preferred_patient_name =
        consent_form.full_name + " (known as #{consent_form.common_name})"
    else
      short_patient_name = consent_form.first_name
      full_and_preferred_patient_name = consent_form.full_name
    end

    template_mail(
      "604ee667-c996-471e-b986-79ab98d0767c",
      to: consent_form.parent_email,
      reply_to_id: reply_to_id(consent_form:),
      personalisation: {
        short_date: consent_form.session.date.strftime("%-d %B"),
        parent_name: consent_form.parent_name,
        location_name: consent_form.session.location.name,
        long_date: consent_form.session.date.strftime("%A %-d %B"),
        full_and_preferred_patient_name:,
        short_patient_name:
      }
    )
  end

  def confirmation_injection(consent_form)
    full_and_preferred_patient_name =
      if consent_form.common_name.present?
        consent_form.full_name + " (known as #{consent_form.common_name})"
      else
        consent_form.full_name
      end

    template_mail(
      "4d09483a-8181-4acb-8ba3-7abd6c8644cd",
      to: consent_form.parent_email,
      reply_to_id: reply_to_id(consent_form:),
      personalisation: {
        short_date: consent_form.session.date.strftime("%-d %B"),
        parent_name: consent_form.parent_name,
        location_name: consent_form.session.location.name,
        long_date: consent_form.session.date.strftime("%A %-d %B"),
        full_and_preferred_patient_name:,
        reason_for_refusal:
          I18n.t(
            "consent_form_mailer.reasons_for_refusal.#{consent_form.reason}"
          )
      }
    )
  end

  def confirmation_refused(consent_form)
    if consent_form.common_name.present?
      short_patient_name = consent_form.common_name
      full_and_preferred_patient_name =
        consent_form.full_name + " (known as #{consent_form.common_name})"
    else
      short_patient_name = consent_form.first_name
      full_and_preferred_patient_name = consent_form.full_name
    end

    template_mail(
      "5a676dac-3385-49e4-98c2-fc6b45b5a851",
      to: consent_form.parent_email,
      reply_to_id: reply_to_id(consent_form:),
      personalisation: {
        short_date: consent_form.session.date.strftime("%-d %B"),
        parent_name: consent_form.parent_name,
        location_name: consent_form.session.location.name,
        long_date: consent_form.session.date.strftime("%A %-d %B"),
        full_and_preferred_patient_name:,
        short_patient_name:,
        team_email: I18n.t("service.email"),
        team_phone: I18n.t("service.temporary_cumbria_phone")
      }
    )
  end
end
