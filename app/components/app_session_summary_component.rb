# frozen_string_literal: true

class AppSessionSummaryComponent < ViewComponent::Base
  def initialize(
    session,
    patient_count: nil,
    full_width: false,
    show_consent_forms: false,
    show_dates: false,
    show_location: false,
    show_status: false
  )
    @session = session
    @patient_count = patient_count
    @full_width = full_width
    @show_consent_forms = show_consent_forms
    @show_dates = show_dates
    @show_location = show_location
    @show_status = show_status
  end

  def call = helpers.govuk_summary_list(rows:, classes:)

  private

  attr_reader :session,
              :patient_count,
              :full_width,
              :show_consent_forms,
              :show_dates,
              :show_location,
              :show_status

  delegate :location, to: :session

  def rows
    [
      location_row,
      school_urn_row,
      patient_count_row,
      programmes_row,
      year_groups_row,
      status_row,
      dates_row,
      consent_period_row,
      consent_forms_row
    ].compact
  end

  def location_row
    return unless show_location

    text = [
      location.name,
      helpers.format_address_single_line(location)
    ].compact_blank.join(", ")

    { key: { text: "Location" }, value: { text: } }
  end

  def school_urn_row
    return unless show_location && location.school?

    {
      key: {
        text: "School URN"
      },
      value: {
        text: tag.span(location.urn_and_site, class: "app-u-code")
      }
    }
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

  def consent_forms_row
    return unless show_consent_forms

    links = [*online_consent_links, *download_consent_links]
    text =
      tag.ul(class: "nhsuk-list") do
        safe_join(links.map { |link| tag.li(link) })
      end

    { key: { text: "Consent forms" }, value: { text: } }
  end

  def online_consent_links
    return [] unless session.open_for_consent?

    ProgrammeGrouper
      .call(session.programmes)
      .map do |_group, programmes|
        helpers.govuk_link_to(
          "View the #{programmes.map(&:name).to_sentence} online consent form",
          start_parent_interface_consent_forms_path(
            session,
            programmes.map(&:to_param).join("-")
          ),
          new_tab: true
        )
      end
  end

  def download_consent_links
    session.programmes.map do |programme|
      link_to(
        "Download the #{programme.name} consent form (PDF)",
        consent_form_programme_path(programme)
      )
    end
  end

  def classes
    full_width ? %w[app-summary-list--full-width] : []
  end
end
