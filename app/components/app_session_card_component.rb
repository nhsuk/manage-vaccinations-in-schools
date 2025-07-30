# frozen_string_literal: true

class AppSessionCardComponent < ViewComponent::Base
  def initialize(session, patient_count:)
    super

    @session = session
    @patient_count = patient_count
  end

  def call
    render AppCardComponent.new(**card_options) do |card|
      card.with_heading { session.location.name }
      govuk_summary_list(rows:)
    end
  end

  private

  attr_reader :session, :patient_count

  delegate :programmes, to: :session

  def card_options = { link_to: session_path(session), compact: true }

  def rows
    [cohort_row, programmes_row, status_row, dates_row, consent_period_row]
  end

  def cohort_row
    {
      key: {
        text: "Cohort"
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

  def status_row
    {
      key: {
        text: "Status"
      },
      value: {
        text: helpers.session_status_tag(session)
      }
    }
  end

  def dates_row
    {
      key: {
        text: "Session dates"
      },
      value: {
        text:
          tag.ul(class: "nhsuk-list") do
            safe_join(session.dates.map { tag.li(it.to_fs(:long_day_of_week)) })
          end
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
end
