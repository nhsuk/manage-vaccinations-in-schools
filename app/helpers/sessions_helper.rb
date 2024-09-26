# frozen_string_literal: true

module SessionsHelper
  def session_consent_period(session)
    if session.close_consent_at.nil?
      "Not provided"
    elsif session.close_consent_at.past?
      "Closed #{session.close_consent_at.to_fs(:short)}"
    else
      "Open until #{session.close_consent_at.to_fs(:short)}"
    end
  end

  def session_location(session, part_of_sentence: false)
    if (location = session.location).present?
      location.name
    else
      part_of_sentence ? "unknown location" : "Unknown location"
    end
  end

  def session_status_tag(session)
    if session.unscheduled?
      govuk_tag(text: "No sessions scheduled", colour: "purple")
    elsif session.completed?
      govuk_tag(text: "All sessions completed", colour: "green")
    else
      govuk_tag(text: "Session in progress")
    end
  end
end
