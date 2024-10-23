# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  def school_reminder
    app_template_mail(:hpv_school_session_reminder)
  end

  def clinic_initial_invitation
    app_template_mail(:hpv_clinic_invitation)
  end

  def clinic_subsequent_invitation
    app_template_mail(:hpv_clinic_invitation_subsequent)
  end
end
