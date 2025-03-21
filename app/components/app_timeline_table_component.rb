# frozen_string_literal: true

class AppTimelineTableComponent < ViewComponent::Base
  EVENT_COLOUR_MAPPING = {
    "CohortImport" => "blue",
    "ClassImport" => "purple",
    "PatientSession" => "green",
    "Consent" => "yellow",
    "Triage" => "red",
    "VaccinationRecord" => "grey",
    "SchoolMove" => "orange",
    "SchoolMoveLogEntry" => "pink"
  }.freeze

  def initialize(events:, patient_id:, omit_details: false)
    super
    @events = events
    @patient_id = patient_id
    @omit_details = omit_details
  end

  def format_time(date_time)
    date_time.strftime("%H:%M:%S")
  end

  def format_event_details(details)
    return "" if details.blank?
    details.to_s.html_safe
  end

  def tag_colour(event_type)
    return "light-blue" if event_type.end_with?("-Audit")
    EVENT_COLOUR_MAPPING.fetch(event_type, "grey")
  end
end
