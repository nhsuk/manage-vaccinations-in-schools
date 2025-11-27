# frozen_string_literal: true

class AppSchoolCardComponent < ViewComponent::Base
  def initialize(school, patient_count:, next_session_date:)
    @school = school
    @patient_count = patient_count
    @next_session_date = next_session_date
  end

  def call
    render AppCardComponent.new(link_to:, compact: true) do |card|
      card.with_heading(level: 4) { school.name }
      govuk_summary_list(rows:)
    end
  end

  private

  attr_reader :school, :patient_count, :next_session_date

  delegate :govuk_summary_list, to: :helpers

  def link_to = nil

  def rows
    [
      patient_count_row,
      urn_row,
      phase_row,
      address_row,
      next_session_date_row
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

  def urn_row
    {
      key: {
        text: "URN"
      },
      value: {
        text: tag.span(school.urn_and_site, class: "app-u-monospace")
      }
    }
  end

  def phase_row
    { key: { text: "Phase" }, value: { text: school.human_enum_name(:phase) } }
  end

  def address_row
    {
      key: {
        text: "Address"
      },
      value: {
        text: helpers.format_address_multi_line(school)
      }
    }
  end

  def next_session_date_row
    return if next_session_date.nil?

    {
      key: {
        text: "Next session"
      },
      value: {
        text: next_session_date.to_fs(:long)
      }
    }
  end
end
