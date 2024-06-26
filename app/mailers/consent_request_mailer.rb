# frozen_string_literal: true

class ConsentRequestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def consent_request(session, patient)
    template_mail(
      EMAILS[:hpv_session_consent_request],
      **opts(session, patient)
    )
  end

  def consent_reminder(session, patient)
    template_mail(
      EMAILS[:hpv_session_consent_reminder],
      **opts(session, patient)
    )
  end

  private

  def host
    if Rails.env.development? || Rails.env.test?
      "http://localhost:4000"
    else
      "https://#{Settings.give_or_refuse_consent_host}"
    end
  end

  def opts(session, patient)
    @session = session
    @patient = patient

    { to:, reply_to_id:, personalisation: consent_request_personalisation }
  end

  def consent_request_personalisation
    personalisation.merge(
      consent_link:,
      session_date: @session.date.to_fs(:sunday_1_may),
      session_short_date: @session.date.to_fs(:"1_may"),
      close_consent_date: @session.close_consent_at.to_fs(:sunday_1_may),
      close_consent_short_date: @session.close_consent_at.to_fs(:"1_may")
    )
  end

  def consent_link
    host + start_session_parent_interface_consent_forms_path(@session)
  end
end
