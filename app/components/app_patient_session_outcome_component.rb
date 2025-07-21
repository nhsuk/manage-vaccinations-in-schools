# frozen_string_literal: true

class AppPatientSessionOutcomeComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-m">Programme outcome</h3>
    
    <%= render AppCardComponent.new(heading_level: 4, colour:) do |card| %>
      <% card.with_heading { heading } %>
      <%= render AppPatientVaccinationTableComponent.new(
            patient,
            programme:,
            show_caption: true
          ) %>
    <% end %>
  ERB

  def initialize(patient_session, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def render?
    patient.vaccination_records.exists?
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, to: :patient_session

  def colour
    I18n.t(status, scope: %i[status programme colour])
  end

  def heading
    "#{programme.name}: #{I18n.t(status, scope: %i[status programme label])}"
  end

  def vaccination_status
    @vaccination_status ||=
      patient.vaccination_statuses.find_or_initialize_by(programme:)
  end

  delegate :status, to: :vaccination_status
end
