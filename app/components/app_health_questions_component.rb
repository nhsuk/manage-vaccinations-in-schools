class AppHealthQuestionsComponent < ViewComponent::Base
  def initialize(consent_response:)
    super

    @consent_response = consent_response
  end

  def health_questions
    @consent_response&.health_questions
  end
end
