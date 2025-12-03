# frozen_string_literal: true

class AppSessionDetailsComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% if Flipper.enabled?(:schools_and_sessions) %>
        <% card.with_heading(level: 3) { "Session details" } %>
        <%= render AppSessionSummaryComponent.new(
            session,
            patient_count: session.patients.count,
            show_consent_forms: true,
            show_location: true,
            show_status: true,
          ) %>
      <% else %>
        <% card.with_heading(level: 3) { session.clinic? ? "About this clinic" : "About this school" } %>
        <%= render AppSessionLocationSummaryComponent.new(session) %>
      <% end %>
    <% end %>
  ERB

  def initialize(session)
    @session = session
  end

  private

  attr_reader :session
end
