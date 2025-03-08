# frozen_string_literal: true

class AppPatientSessionConsentComponent < ViewComponent::Base
  erb_template <<-ERB
    <h2 class="nhsuk-heading-m">Consent</h2>
    
    <%= render AppConsentCardComponent.new(patient_session:, programme:) %>

    <% if show_health_answers? %>
      <%= render AppHealthAnswersCardComponent.new(
        consents,
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

  def consents
    @consents ||= ConsentGrouper.call(patient.consents, programme:)
  end

  def show_health_answers?
    consents.any?(&:response_given?)
  end
end
