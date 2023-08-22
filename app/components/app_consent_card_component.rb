class AppConsentCardComponent < ViewComponent::Base
  def initialize(session:, patient:, consent:, route:)
    super

    @session = session
    @patient = patient
    @consent = consent
    @route = route
  end
end
