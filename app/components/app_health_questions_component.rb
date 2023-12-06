class AppHealthQuestionsComponent < ViewComponent::Base
  def initialize(consents:)
    super

    # HACK: This needs to work with multiple consents
    @consent = consents.first
  end

  def health_questions
    @consent&.health_questions
  end
end
