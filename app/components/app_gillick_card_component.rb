class AppGillickCardComponent < ViewComponent::Base
  def initialize(consent_response:, patient_session:)
    super

    @consent_response = consent_response
    @patient_session = patient_session
  end
end
