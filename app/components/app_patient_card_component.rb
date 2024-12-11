# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new do |card| %>
      <% card.with_heading { "Child record" } %>

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
