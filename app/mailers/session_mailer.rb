# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def school_reminder
    app_template_mail(:hpv_school_session_reminder)
  end
end
