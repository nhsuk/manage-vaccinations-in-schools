# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% card.with_heading { "Child record" } %>
      
      <% if Flipper.enabled?(:release_1_2) %>
        <% if @patient.date_of_death.present? %>
          <%= render AppNoticeStatusComponent.new(
            text: "Record updated with child’s date of death"
          ) %>
        <% end %>
        
        <% if @patient.invalidated? %>
          <%= render AppNoticeStatusComponent.new(
            text: "Record flagged as invalid"
          ) %>
        <% end %>
        
        <% if @patient.restricted? %>
          <%= render AppNoticeStatusComponent.new(
            text: "Record flagged as sensitive"
          ) %>
        <% end %>
      <% end %>

      <%= render AppPatientSummaryComponent.new(
               patient,
               show_parent_or_guardians: true
             ) %>

      <%= content %>
    <% end %>
  ERB

  def initialize(patient)
    super

    @patient = patient
  end

  private

  attr_reader :patient
end
