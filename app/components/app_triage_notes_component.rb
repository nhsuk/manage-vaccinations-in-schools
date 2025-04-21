# frozen_string_literal: true

class AppTriageNotesComponent < ViewComponent::Base
  erb_template <<-ERB
    <% events.each_with_index do |event, index| %>
      <%= render AppLogEventComponent.new(**event) %>

      <% if index < events.size - 1 %>
        <hr class="nhsuk-section-break nhsuk-section-break--visible nhsuk-section-break--m">
      <% end %>
    <% end %>
  ERB

  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def render?
    events.present?
  end

  delegate :patient, :session, to: :@patient_session

  def events
    @events ||=
      (triage_events + pre_screening_events).sort_by { -_1[:time].to_i }
  end

  def triage_events
    patient
      .triages
      .where(programme: @programme)
      .includes(:performed_by)
      .map do |triage|
        {
          title: "Triaged decision: #{triage.human_enum_name(:status)}",
          body: triage.notes,
          at: triage.created_at,
          by: triage.performed_by,
          invalidated: triage.invalidated?
        }
      end
  end

  def pre_screening_events
    @patient_session
      .pre_screenings
      .where.not(notes: "")
      .includes(:performed_by)
      .map do |pre_screening|
        {
          title: "Completed pre-screening checks",
          body: pre_screening.notes,
          at: pre_screening.created_at,
          by: pre_screening.performed_by
        }
      end
  end
end
