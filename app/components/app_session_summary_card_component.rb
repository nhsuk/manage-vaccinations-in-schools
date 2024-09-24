# frozen_string_literal: true

class AppSessionSummaryCardComponent < ViewComponent::Base
  def initialize(session:)
    super

    @session = session
  end

  def school
    helpers.session_location(@session)
  end

  def vaccines
    @session.programmes.map(&:name)
  end

  def date
    @session.date.to_fs(:long_day_of_week)
  end

  def time
    @session.human_enum_name(:time_of_day)
  end

  def cohort
    I18n.t("children", count: @session.patients.count)
  end

  def consent_requests
    if (date = @session.send_consent_requests_at).present?
      "Send on #{date.to_fs(:long_day_of_week)}"
    end
  end

  def consent_reminders
    if (date = @session.send_consent_reminders_at).present?
      "Send on #{date.to_fs(:long_day_of_week)}"
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
