# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def session_reminder(session:, patient:, parent:)
    template_mail(
      EMAILS[:hpv_session_session_reminder],
      **opts(session, patient, parent)
    )
  end

  private

  def opts(session, patient, parent)
    @session = session
    @patient = patient
    @parent = parent

    { to:, reply_to_id:, personalisation: }
  end
end
