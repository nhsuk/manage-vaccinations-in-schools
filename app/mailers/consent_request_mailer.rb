class ConsentRequestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def consent_request(session, patient)
    template_mail(
      "6aa04f0d-94c2-4a6b-af97-a7369a12f681",
      **opts(session, patient)
    )
  end

  private

  def opts(session, patient)
    @session = session
    @patient = patient

    { to:, reply_to_id:, personalisation: consent_request_personalisation }
  end

  def consent_request_personalisation
    personalisation.merge consent_link:
  end

  def consent_link
    start_session_parent_interface_consent_forms_url(@session)
  end
end
