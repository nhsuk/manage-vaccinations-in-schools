# frozen_string_literal: true

class AppSessionDetailsComponent < ViewComponent::Base
  def initialize(session:)
    super

    @session = session
  end

  def school
    @session.location.name
  end

  def vaccine
    @session.campaign.name
  end

  def date
    @session.date.to_fs(:long_day_of_week)
  end

  def time
    @session.human_enum_name(:time_of_day)
  end

  def cohort
    patients_count = @session.patients.count
    pluralize(patients_count, "child")
  end

  def consent_requests
    "Send on #{@session.send_consent_at.to_fs(:long_day_of_week)}"
  end

  def reminders
    "Send on #{@session.send_reminders_at.to_fs(:long_day_of_week)}"
  end

  def deadline_for_responses
    if @session.date == @session.close_consent_at
      "Allow responses until the day of the session"
    else
      close_consent_at = @session.close_consent_at.to_fs(:long_day_of_week)
      "Allow responses until #{close_consent_at}"
    end
  end
end
