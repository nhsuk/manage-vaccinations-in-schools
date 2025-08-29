# frozen_string_literal: true

class AppTimelineComponent < ViewComponent::Base
  erb_template <<-ERB
    <ul class="app-timeline">
      <% @items.each do |item| %>
        <% next if item.blank? %>

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
              <%= item[:heading_text].html_safe %>
            </h3>

            <% if item[:description].present? %>
              <p class="app-timeline__description"><%= item[:description].html_safe %></p>
            <% end %>
          </div>
        </li>
      <% end %>
    </ul>
  ERB

  def initialize(items)
    @items = items
  end

  def render?
    @items.present?
  end
end
