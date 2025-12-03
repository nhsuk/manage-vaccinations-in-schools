# frozen_string_literal: true

class AppSessionDatesComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% card.with_heading(level: 3) { heading } %>

      <% if session.started? %>
        <%= render AppSessionDatesTableComponent.new(session) %>
      <% else %>
        <% if dates.present? %>
          <%= tag.ul(class: "nhsuk-list") do %>
            <% dates.each do |date| %>
              <%= tag.li(date.to_fs(:long_day_of_week)) %>
            <% end %>
          <% end %>
          <p class="nhsuk-body">
            Consent period <%= session_consent_period(session).downcase_first %>
          </p>
        <% else %>
          <p class="nhsuk-hint"><%= no_sessions_message %></p>
        <% end %>
      <% end %>

      <% unless Flipper.enabled?(:schools_and_sessions) %>
        <%= render AppSessionButtonsComponent.new(session) %>
      <% end %>
    <% end %>
  ERB

  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :academic_year, :dates, :programmes, to: :session

  delegate :govuk_inset_text, :session_consent_period, to: :helpers

  def heading
    if session.completed?
      "All session dates completed"
    elsif session.today?
      "Session in progress"
    else
      "Scheduled session dates"
    end
  end

  def no_sessions_message
    location_context = session.clinic? ? "clinic" : "school"
    "There are currently no sessions scheduled at this #{location_context}."
  end
end
