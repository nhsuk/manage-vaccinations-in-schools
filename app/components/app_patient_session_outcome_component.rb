# frozen_string_literal: true

class AppPatientSessionOutcomeComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-m">Programme outcome</h3>
    
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
      .where(programme:)
      .includes(:programme)
      .any? { it.show_in_academic_year?(academic_year) }
  end

  private

  attr_reader :patient, :session, :programme

  delegate :academic_year, to: :session

  def colour
    I18n.t(status, scope: %i[status programme colour])
  end

  def heading
    "#{programme.name}: #{I18n.t(status, scope: %i[status programme label])}"
  end

  def vaccination_status
    @vaccination_status ||=
      patient.vaccination_status(programme:, academic_year:)
  end

  delegate :status, to: :vaccination_status
end
