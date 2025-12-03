# frozen_string_literal: true

class AppSessionSummaryComponent < ViewComponent::Base
  def initialize(
    session,
    patient_count: nil,
    full_width: false,
    show_dates: false,
    show_status: false
  )
    @session = session
    @patient_count = patient_count
    @full_width = full_width
    @show_dates = show_dates
    @show_status = show_status
  end

  def call = helpers.govuk_summary_list(rows:, classes:)

  private

  attr_reader :session, :patient_count, :full_width, :show_dates, :show_status

  def rows
    [
      patient_count_row,
      programmes_row,
      year_groups_row,
      status_row,
      dates_row,
      consent_period_row
    ].compact
  end

  def patient_count_row
    return if patient_count.nil?

    {
      key: {
        text: "Children"
      },
      value: {
        text: I18n.t("children", count: patient_count)
      }
    }
  end

  def programmes_row
    {
      key: {
        text: "Programmes"
      },
      value: {
        text: render(AppProgrammeTagsComponent.new(session.programmes))
      }
    }
  end

  def year_groups_row
    {
      key: {
        text: "Year groups"
      },
      value: {
        text: helpers.format_year_groups(session.year_groups)
      }
    }
  end

  def status_row
    return unless show_status

    {
      key: {
        text: "Status"
      },
      value: {
        text: helpers.session_status(session)
      }
    }
  end

  def dates_row
    return unless show_dates

    {
      key: {
        text: "Date".pluralize(session.dates.length)
      },
      value: {
        text: helpers.session_dates(session)
      }
    }
  end

  def consent_period_row
    {
      key: {
        text: "Consent period"
      },
      value: {
        text: helpers.session_consent_period(session)
      }
    }
  end

  def classes
    full_width ? %w[app-summary-list--full-width] : []
  end
end
