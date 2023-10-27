class ConsentFormMailer < ApplicationMailer
  def confirmation(consent_form)
    template_mail(
      "7cda7ae5-99a2-4c40-9a3e-1863e23f7a73",
      to: consent_form.parent_email,
      personalisation: {
        short_date: consent_form.session.date.strftime("%-d %B"),
        long_date: consent_form.session.date.strftime("%A %-d %B"),
        parent_name: consent_form.parent_name,
        patient_name: consent_form.full_name,
        location_name: consent_form.session.location.name,
        short_patient_name:
          consent_form.common_name.presence || consent_form.first_name,
        team_email: I18n.t("service.email")
      }
    )
  end
end
