class AppConsentCardComponent < ViewComponent::Base
  def initialize(session:, patient:, consent:, route:)
    super

    @session = session
    @patient = patient
    @consent = consent
    @route = route
  end

  def display_health_questions?
    @consent&.response_given?
  end
end
