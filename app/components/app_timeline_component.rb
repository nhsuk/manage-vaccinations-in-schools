# frozen_string_literal: true

class AppTimelineComponent < ViewComponent::Base
  erb_template <<-ERB
    <ul class="app-timeline">
      <% @items.each do |item| %>
        <% next if item.blank? %>

        <% if item[:type] == :section_header %>
          <li>
            <h3 class="nhsuk-heading-s">
              <%= item[:date] %>
            </h3>
          </li>
        <% else %>
          <li class="app-timeline__item <%= 'app-timeline__item--past' if item[:is_past_item] %>">
            <% if item[:active] || item[:is_past_item] %>
              <svg class="app-timeline__badge" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
                <circle cx="14" cy="14" r="13" fill="#005EB8"/>
              </svg>
            <% else %>
              <svg class="app-timeline__badge app-timeline__badge--small" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
                <circle cx="7" cy="7" r="6" fill="white" stroke="#AEB7BD" stroke-width="2"/>
              </svg>
            <% end %>

            <div class="app-timeline__content">
              <h3 class="app-timeline__header <%= 'nhsuk-u-font-weight-bold' if item[:active] %>">
                <%= format_heading(item).html_safe %>
              </h3>

              <% if item[:description].present? || item[:details].present? %>
                <div class="app-timeline__description">
                  <%= format_description(item).html_safe %>
                </div>
              <% end %>
            </div>
          </li>
        <% end %>
      <% end %>
    </ul>
  ERB

  def initialize(items)
    @items = items
  end

  def render?
    @items.present?
  end

  private

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

  def format_heading(item)
    if item[:type] && item[:created_at]
      time = format_time(item[:created_at])
      event_tag =
        govuk_tag(
          text: item[:event_type],
          colour: tag_colour(item[:event_type])
        )
      "#{event_tag} at #{time}"
    elsif item[:heading_text]
      item[:heading_text]
    end
  end

  def format_description(item)
    if item[:details].present?
      formatted_details = format_event_details(item[:details])
      id_info =
        item[:id] ? "<p class=\"timeline__byline\">id: #{item[:id]}</p>" : ""
      "#{id_info}#{formatted_details}"
    elsif item[:description].present?
      item[:description]
    end
  end

  def format_time(date_time)
    date_time.strftime("%H:%M:%S")
  end

  def format_event_details(details)
    return "" if details.blank?

    if details.is_a?(Hash)
      formatted =
        details.map do |key, value|
          if value.is_a?(Hash)
            nested =
              value.map do |sub_key, sub_value|
                nested_value =
                  sub_value.is_a?(String) ? sub_value : sub_value.inspect
                "<div style='margin-left: 1em;'><strong>#{sub_key}:</strong> #{nested_value}</div>"
              end
            "<div><strong>#{key}:</strong>#{nested.join}</div>"
          else
            "<div><strong>#{key}:</strong> #{value}</div>"
          end
        end
      formatted.join
    else
      details.to_s
    end
  end

  def tag_colour(type)
    return "light-blue" if type.end_with?("-Audit")
    EVENT_COLOUR_MAPPING.fetch(type, "grey")
  end

  def govuk_tag(text:, colour:)
    helpers.govuk_tag(text: text, colour: colour)
  end
end
