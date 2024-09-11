# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def session_reminder(session:, patient:, parent:)
    app_template_mail(:hpv_session_session_reminder, session, patient, parent)
  end
end
