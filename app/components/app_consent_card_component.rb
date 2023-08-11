class AppConsentCardComponent < ViewComponent::Base
  def initialize(session:, patient:, consent:)
    super

    @session = session
    @patient = patient
    @consent = consent
  end
end
