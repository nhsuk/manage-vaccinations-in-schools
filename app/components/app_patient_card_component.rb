# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% card.with_heading { "Child" } %>
      
      <% if @patient.date_of_death.present? %>
        <%= render AppStatusComponent.new(
          text: "Record updated with child’s date of death"
        ) %>
      <% end %>
      
      <% if @patient.invalidated? %>
        <%= render AppStatusComponent.new(
          text: "Record flagged as invalid"
        ) %>
      <% end %>
      
      <% if @patient.restricted? %>
        <%= render AppStatusComponent.new(
          text: "Record flagged as sensitive"
        ) %>
      <% end %>

      <%= render AppPatientSummaryComponent.new(patient) %>

      <% unless patient.restricted? %>
        <% parent_relationships.each do |parent_relationship| %>
          <h3 class="nhsuk-heading-s nhsuk-u-margin-bottom-2">
            <%= parent_relationship.label_with_parent %>
          </h3>
  
          <%= render AppParentSummaryComponent.new(parent_relationship:) %>
        <% end %>
      <% end %>

      <%= content %>
    <% end %>
  ERB

  def initialize(patient)
    super

    @patient = patient
  end

  private

  attr_reader :patient

  delegate :parent_relationships, to: :patient
end
