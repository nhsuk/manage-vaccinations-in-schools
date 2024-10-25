# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def school_reminder
    app_template_mail(:session_school_reminder)
  end

  def clinic_initial_invitation
    app_template_mail(:session_clinic_initial_invitation)
  end

  def clinic_subsequent_invitation
    app_template_mail(:session_clinic_subsequent_invitation)
  end
end
