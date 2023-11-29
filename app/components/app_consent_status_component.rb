class AppConsentStatusComponent < ViewComponent::Base
  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end
end
