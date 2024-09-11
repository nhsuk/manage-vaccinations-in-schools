# frozen_string_literal: true

class ConsentRequestMailer < ApplicationMailer
  def consent_request
    app_template_mail(:hpv_session_consent_request)
  end

  def consent_reminder
    app_template_mail(:hpv_session_consent_reminder)
  end
end
