# frozen_string_literal: true

class ConsentFormMailer < ApplicationMailer
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

  def give_feedback
    app_template_mail(:parental_consent_give_feedback)
  end
end
