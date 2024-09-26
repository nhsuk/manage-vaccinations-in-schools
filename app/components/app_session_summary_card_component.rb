# frozen_string_literal: true

class AppSessionSummaryCardComponent < ViewComponent::Base
  def initialize(session)
    super

    @session = session
  end

  def programmes
    safe_join(@session.programmes.map(&:name), tag.br)
  end

  def session_dates
    if (dates = @session.dates).present?
      safe_join(dates.map { _1.value.to_fs(:long_day_of_week) }, tag.br)
    else
      "Not provided"
    end
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
end
