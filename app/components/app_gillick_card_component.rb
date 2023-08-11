class AppGillickCardComponent < ViewComponent::Base
  def initialize(consent:, patient_session:)
    super

    @consent = consent
    @patient_session = patient_session
  end
end
