# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def session_reminder(session:, patient:)
    template_mail(
      EMAILS[:hpv_session_session_reminder],
      **opts(session, patient)
    )
  end

  private

  def opts(session, patient)
    @session = session
    @patient = patient

    { to:, reply_to_id:, personalisation: }
  end
end
