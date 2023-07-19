class AppConsentCardComponent < ViewComponent::Base
  def initialize(session:, patient:, consent_response:)
    super

    @session = session
    @patient = patient
    @consent_response = consent_response
  end
end
