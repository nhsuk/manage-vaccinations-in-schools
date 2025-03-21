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

  def initialize(events:, patient_id:, comparison: false)
    super
    @events = events
    @patient_id = patient_id
    @comparison = comparison
  end

  def format_time(date_time)
    date_time.strftime("%H:%M:%S")
  end

  def format_event_details(details)
    return "" if details.blank?

    if details.is_a?(Hash)
      formatted =
        # stree-ignore
        details.map do |key, value|
          if value.is_a?(Hash)
            nested =
              value
                .map { |sub_key, sub_value|
                  nested_value =
                    sub_value.is_a?(String) ? sub_value : sub_value.inspect
                  "<div style='margin-left: 1em;'><strong>#{sub_key}:</strong> #{nested_value}</div>"
                }
                .join
            "<div><strong>#{key}:</strong> #{nested}</div>"
          else
            "<div><strong>#{key}:</strong> #{value}</div>"
          end
        end

      formatted.join.html_safe
    else
      details.to_s.html_safe
    end
  end

  def tag_colour(event_type)
    return "light-blue" if event_type.end_with?("-Audit")
    EVENT_COLOUR_MAPPING.fetch(event_type, "grey")
  end
end
