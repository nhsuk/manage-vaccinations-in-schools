# frozen_string_literal: true

class AppSessionDatesComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% if session.today? %>
        <%= govuk_inset_text classes: "nhsuk-u-margin-top-4 nhsuk-u-margin-bottom-4" do %>
          <%= link_to t(".still_to_vaccinate_message", count: still_to_vaccinate_count),
                      session_patients_path(session, still_to_vaccinate: 1) %>
        <% end %>
      <% end %>

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

  def still_to_vaccinate_count
    session
      .patients
      .includes_statuses
      .consent_given_and_safe_to_vaccinate(
        programmes:,
        academic_year:,
        vaccine_methods: nil,
        without_gelatine: nil
      )
      .count
  end

  def no_sessions_message
    location_context = session.clinic? ? "clinic" : "school"
    "There are currently no sessions scheduled at this #{location_context}."
  end
end
