# frozen_string_literal: true

class AppSessionDetailsComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% card.with_heading(level: 3) { "Session details" } %>
      <%= render AppSessionSummaryComponent.new(
          session,
          patient_count: session.patients.count,
          show_consent_forms: true,
          show_dates: true,
          show_location: true,
          show_status: true,
        ) %>

      <% unless Flipper.enabled?(:schools_and_sessions) %>
        <%= govuk_button_link_to "Import class lists", import_session_path(session), secondary: true %>
      <% end %>
    <% end %>
  ERB

  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :govuk_button_link_to, to: :helpers
end
