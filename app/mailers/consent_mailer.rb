# frozen_string_literal: true

class ConsentMailer < ApplicationMailer
  def confirmation_given
    app_template_mail(:consent_confirmation_given)
  end

  def confirmation_triage
    app_template_mail(:consent_confirmation_triage)
  end

  def confirmation_injection
    app_template_mail(:consent_confirmation_injection)
  end

  def confirmation_refused
    app_template_mail(:consent_confirmation_refused)
  end

  def school_request
    app_template_mail(:consent_school_request)
  end

  def school_initial_reminder
    app_template_mail(:consent_school_initial_reminder)
  end

  def school_subsequent_reminder
    app_template_mail(:consent_school_subsequent_reminder)
  end

  def clinic_request
    app_template_mail(:consent_clinic_request)
  end
end
