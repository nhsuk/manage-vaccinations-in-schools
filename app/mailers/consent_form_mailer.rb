class ConsentFormMailer < ApplicationMailer
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

    template_mail(
      "7cda7ae5-99a2-4c40-9a3e-1863e23f7a73",
      to: consent_form.parent_email,
      personalisation: {
        short_date: consent_form.session.date.strftime("%-d %B"),
        parent_name: consent_form.parent_name,
        location_name: consent_form.session.location.name,
        long_date: consent_form.session.date.strftime("%A %-d %B"),
        full_and_preferred_patient_name:,
        short_patient_name:,
        short_patient_name_apos:,
        team_email: I18n.t("service.email"),
        team_phone: I18n.t("service.temporary_cumbria_phone")
      }
    )
  end
end
