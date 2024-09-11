# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def session_reminder
    app_template_mail(:hpv_session_session_reminder)
  end
end
