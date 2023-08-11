class AppHealthQuestionsComponent < ViewComponent::Base
  def initialize(consent:)
    super

    @consent = consent
  end

  def health_questions
    @consent&.health_questions
  end
end
