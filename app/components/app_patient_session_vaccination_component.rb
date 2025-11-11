# frozen_string_literal: true

class AppPatientSessionVaccinationComponent < AppPatientSessionSectionComponent
  erb_template <<-ERB
    <h3 class="nhsuk-heading-m">Programme status</h3>
    
    <%= render AppCardComponent.new(feature: true) do |card| %>
      <% card.with_heading(level: 4, colour:) { heading } %>
      <%= render AppPatientVaccinationTableComponent.new(
            patient,
            programme:,
            academic_year:,
            show_caption: true
          ) %>
    <% end %>
  ERB

  def render?
    patient
      .vaccination_records
      .where_programme(programme)
      .any? { it.show_in_academic_year?(academic_year) }
  end

  private

  def resolved_status
    @resolved_status ||= patient_status_resolver.vaccination
  end
end
