# frozen_string_literal: true

class AppPatientSessionVaccinationComponent < ViewComponent::Base
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

  def initialize(patient:, session:, programme:)
    @patient = patient
    @session = session
    @programme = programme
  end

  def render?
    patient
      .vaccination_records
      .for_programme(programme)
      .any? { it.show_in_academic_year?(academic_year) }
  end

  private

  attr_reader :patient, :session, :programme

  delegate :academic_year, :team, to: :session

  def colour = resolved_status.fetch(:colour)

  def heading =
    "#{resolved_status.fetch(:prefix)}: #{resolved_status.fetch(:text)}"

  def resolved_status
    @resolved_status ||=
      PatientProgrammeStatusResolver.call(
        patient,
        programme_type: programme.type,
        academic_year:,
        context_location_id: session.location_id
      )
  end
end
