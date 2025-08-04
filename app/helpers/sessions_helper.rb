# frozen_string_literal: true

module SessionsHelper
  def session_consent_period(session)
    open_at = session.open_consent_at
    close_at = session.close_consent_at

    if open_at.nil? || close_at.nil?
      "Not provided"
    elsif open_at.future?
      "Opens #{open_at.to_fs(:short)}"
    elsif close_at.future?
      "Open from #{open_at.to_fs(:short)} until #{close_at.to_fs(:short)}"
    else
      "Closed #{close_at.to_fs(:short)}"
    end
  end

  def session_status_tag(session)
    if session.unscheduled?
      govuk_tag(text: "No sessions scheduled", colour: "purple")
    elsif session.completed?
      govuk_tag(text: "All sessions completed", colour: "green")
    else
      govuk_tag(text: "Sessions scheduled", colour: "blue")
    end
  end
end
