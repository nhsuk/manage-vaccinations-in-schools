# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(heading_level:, section: true) do |card| %>
      <% card.with_heading { "Child’s details" } %>

      <% if patient.date_of_death.present? %>
        <%= render AppStatusComponent.new(
          text: "Record updated with child’s date of death"
        ) %>
      <% end %>

      <% if patient.invalidated? %>
        <%= render AppStatusComponent.new(
          text: "Record flagged as invalid"
        ) %>
      <% end %>

      <% if patient.restricted? %>
        <%= render AppStatusComponent.new(
          text: "Record flagged as sensitive"
        ) %>
      <% end %>

      <%= render AppChildSummaryComponent.new(patient, show_parents: true, change_links:, remove_links:) %>

      <%= content %>
    <% end %>
  ERB

  def initialize(patient, change_links: {}, remove_links: {}, heading_level: 3)
    super

    @patient = patient
    @change_links = change_links
    @remove_links = remove_links
    @heading_level = heading_level
  end

  private

  attr_reader :patient, :change_links, :remove_links, :heading_level
end
