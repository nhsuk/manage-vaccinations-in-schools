# frozen_string_literal: true

class AppSessionDetailsComponent < ViewComponent::Base
  def initialize(session:)
    super

    @session = session
  end

  def school
    helpers.session_location(@session)
  end

  def vaccine
    @session.programme.name
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
    if @session.send_consent_at.present?
      "Send on #{@session.send_consent_at.to_fs(:long_day_of_week)}"
    end
  end

  def reminders
    if @session.send_reminders_at.present?
      "Send on #{@session.send_reminders_at.to_fs(:long_day_of_week)}"
    end
  end

  def deadline_for_responses
    return nil if @session.close_consent_at.blank?

    if @session.date == @session.close_consent_at
      "Allow responses until the day of the session"
    else
      close_consent_at = @session.close_consent_at.to_fs(:long_day_of_week)
      "Allow responses until #{close_consent_at}"
    end
  end
end
