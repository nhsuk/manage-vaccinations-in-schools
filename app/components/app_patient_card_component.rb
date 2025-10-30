# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(section: true) do |card| %>
      <% card.with_heading(level: heading_level) { "Child’s details" } %>
      
      <% important_notices.each do |notice| %>
        <%= render AppStatusComponent.new(text: notice.message) %>
      <% end %>

      <%= render AppChildSummaryComponent.new(
        patient,
        current_team:,
        show_parents: true,
        show_school_and_year_group:,
        change_links:,
        remove_links:
      ) %>

      <%= content %>
    <% end %>
  ERB

  def initialize(
    patient,
    current_team:,
    change_links: {},
    remove_links: {},
    heading_level: 3
  )
    @patient = patient
    @current_team = current_team
    @change_links = change_links
    @remove_links = remove_links
    @heading_level = heading_level
  end

  private

  attr_reader :patient,
              :current_team,
              :change_links,
              :remove_links,
              :heading_level

  def show_school_and_year_group = patient.show_year_group?(team: current_team)

  def important_notices
    ImportantNotice.latest_for_patient(patient:)
  end
end
