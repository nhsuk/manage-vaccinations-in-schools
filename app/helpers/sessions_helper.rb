# frozen_string_literal: true

module SessionsHelper
  def session_academic_year(session)
    academic_year = session.academic_year

    year_1 = academic_year.to_s
    year_2 = (academic_year + 1).to_s
    "#{year_1}/#{year_2[2..3]}"
  end

  def session_consent_period(session)
    if session.close_consent_at.nil?
      "Not provided"
    elsif session.close_consent_at.past?
      "Closed #{session.close_consent_at.to_fs(:short)}"
    else
      "Open until #{session.close_consent_at.to_fs(:short)}"
    end
  end

  def session_status_tag(session)
    if session.unscheduled?
      govuk_tag(text: "No sessions scheduled", colour: "purple")
    elsif session.completed?
      govuk_tag(text: "All sessions completed", colour: "green")
    else
      govuk_tag(text: "Sessions scheduled")
    end
  end
end
