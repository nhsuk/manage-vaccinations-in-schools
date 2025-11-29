# frozen_string_literal: true

class AppSessionCardComponent < ViewComponent::Base
  def initialize(
    session,
    patient_count:,
    heading_as_dates: false,
    full_width: false,
    show_buttons: false,
    show_status: false
  )
    @session = session
    @patient_count = patient_count
    @heading_as_dates = heading_as_dates
    @full_width = full_width
    @show_buttons = show_buttons
    @show_status = show_status
  end

  def call
    render AppCardComponent.new(link_to:, compact: true) do |card|
      card.with_heading(level: 4) { heading }
      safe_join([govuk_summary_list(rows:, classes:), button_group].compact)
    end
  end

  private

  attr_reader :session,
              :patient_count,
              :heading_as_dates,
              :full_width,
              :show_buttons,
              :show_status

  delegate :govuk_button_link_to, :govuk_summary_list, to: :helpers
  delegate :programmes, :year_groups, to: :session

  def link_to = session_path(session)

  def heading
    heading_as_dates ? helpers.session_dates(session) : session.location.name
  end

  def classes
    full_width ? %w[app-summary-list--full-width] : []
  end

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
        text: render(AppProgrammeTagsComponent.new(programmes))
      }
    }
  end

  def year_groups_row
    {
      key: {
        text: "Year groups"
      },
      value: {
        text: helpers.format_year_groups(year_groups)
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
    return if heading_as_dates

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

  def button_group
    return unless show_buttons

    tag.div(class: "nhsuk-button-group") do
      govuk_button_link_to "Edit session",
                           edit_session_path(session),
                           secondary: true,
                           class: "app-button--small"
    end
  end
end
