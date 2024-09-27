# frozen_string_literal: true

class ConsentMailer < ApplicationMailer
  def confirmation
    app_template_mail(:parental_consent_confirmation)
  end

  def confirmation_needs_triage
    app_template_mail(:parental_consent_confirmation_needs_triage)
  end

  def confirmation_injection
    app_template_mail(:parental_consent_confirmation_injection)
  end

  def confirmation_refused
    app_template_mail(:parental_consent_confirmation_refused)
  end

  def request
    app_template_mail(:hpv_session_consent_request)
  end

  def reminder
    app_template_mail(:hpv_session_consent_reminder)
  end
end
