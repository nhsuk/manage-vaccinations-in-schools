# frozen_string_literal: true

class AppPatientSessionOutcomeComponent < ViewComponent::Base
  erb_template <<-ERB
    <h2 class="nhsuk-heading-m">Programme outcome</h2>
    
    <%= render AppCardComponent.new(colour:) do |card| %>
      <% card.with_heading { heading } %>
      <%= render AppPatientVaccinationTableComponent.new(
            vaccination_records: patient.programme_outcome.all[programme],
            show_caption: true,
            show_programme: false,
          ) %>
    <% end %>
  ERB

  def initialize(patient_session, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def render?
    patient.programme_outcome.all[programme].any?
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

  def status
    patient.programme_outcome.status[programme]
  end
end
