# frozen_string_literal: true

class AppLocationCardComponent < ViewComponent::Base
  def initialize(location, patient_count:, next_session_date:)
    @location = location
    @patient_count = patient_count
    @next_session_date = next_session_date
  end

  def call
    render AppCardComponent.new(link_to:, compact: true) do |card|
      card.with_heading(level: 4) { heading }
      govuk_summary_list(rows:)
    end
  end

  private

  attr_reader :location, :patient_count, :next_session_date

  delegate :govuk_summary_list, to: :helpers

  def link_to = nil

  def heading
    if location.generic_clinic?
      "No known school (including home-schooled children)"
    else
      location.name
    end
  end

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
    return if location.urn_and_site.blank?

    {
      key: {
        text: "URN"
      },
      value: {
        text: tag.span(location.urn_and_site, class: "app-u-monospace")
      }
    }
  end

  def phase_row
    return if location.phase.blank?

    {
      key: {
        text: "Phase"
      },
      value: {
        text: location.human_enum_name(:phase)
      }
    }
  end

  def address_row
    return unless location.has_address?

    {
      key: {
        text: "Address"
      },
      value: {
        text: helpers.format_address_multi_line(location)
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
