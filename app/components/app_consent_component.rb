class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session, :consent

  def initialize(patient_session:, consent:, route:)
    super

    @patient_session = patient_session
    @consent = consent
    @route = route
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def display_health_questions?
    @consent&.response_given?
  end

  def open_health_questions?
    @patient_session.consent_given_triage_needed?
  end

  def display_gillick_consent_button?
    @consent.nil? && @patient_session.able_to_vaccinate?
  end
end
