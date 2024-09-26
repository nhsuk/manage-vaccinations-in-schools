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

  def dates
    safe_join(@session.dates.map { _1.value.to_fs(:long_day_of_week) }, tag.br)
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
end
