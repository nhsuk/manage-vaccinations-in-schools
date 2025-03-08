# frozen_string_literal: true

class AppPatientSessionConsentComponent < ViewComponent::Base
  erb_template <<-ERB
    <h2 class="nhsuk-heading-m">Consent</h2>
    
    <%= render AppConsentCardComponent.new(patient_session, programme:) %>

    <% if show_health_answers? %>
      <%= render AppHealthAnswersCardComponent.new(
        latest_consent,
        heading: "All answers to health questions",
      ) %>
    <% end %>
  ERB

  def initialize(patient_session, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, to: :patient_session

  def latest_consent
    patient.consent_outcome.latest[programme]
  end

  def show_health_answers?
    latest_consent.any?(&:response_given?)
  end
end
