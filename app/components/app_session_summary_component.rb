# frozen_string_literal: true

class AppSessionSummaryComponent < ViewComponent::Base
  def initialize(session)
    super

    @session = session
  end

  def call
    govuk_summary_list(
      classes: %w[app-summary-list--full-width nhsuk-u-margin-bottom-4]
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Programmes" }
        row.with_value { programmes }
      end
      summary_list.with_row do |row|
        row.with_key { "Session dates" }
        row.with_value { dates }
      end
      summary_list.with_row do |row|
        row.with_key { "Consent period" }
        row.with_value { consent_period }
      end
      summary_list.with_row do |row|
        row.with_key { "Children" }
        row.with_value { children }
      end
    end
  end

  private

  def programmes
    tag.ul(class: "nhsuk-list") do
      safe_join(@session.programmes.map { tag.li(_1.name) })
    end
  end

  def dates
    if (dates = @session.dates).present?
      tag.ul(class: "nhsuk-list") do
        safe_join(dates.map { tag.li(_1.value.to_fs(:long)) })
      end
    else
      "Not provided"
    end
  end

  def consent_period
    helpers.session_consent_period(@session)
  end

  def children
    "#{I18n.t("children", count: @session.patients.count)} in this session"
  end
end
