# frozen_string_literal: true

class AppPatientSessionRecordComponent < ViewComponent::Base
  erb_template <<-ERB
    <h2 class="nhsuk-heading-m">Record vaccination</h2>
    
    <% if helpers.policy(VaccinationRecord).new? %>
      <%= render AppVaccinateFormComponent.new(
          patient_session:,
          programme:,
          vaccinate_form:,
        ) %>
    <% end %>
  ERB

  def initialize(patient_session, programme:, vaccinate_form:)
    super

    @patient_session = patient_session
    @programme = programme
    @vaccinate_form = vaccinate_form
  end

  def render?
    patient.consent_given_and_safe_to_vaccinate?(programme:) &&
      (
        patient_session.register_outcome.attending? ||
          patient_session.register_outcome.completed?
      )
  end

  private

  attr_reader :patient_session, :programme, :vaccinate_form

  delegate :patient, to: :patient_session
end
