# frozen_string_literal: true

module HasHealthAnswers
  extend ActiveSupport::Concern

  included do
    serialize :health_answers, coder: HealthAnswer::ArraySerializer

    encrypts :health_answers if respond_to?(:encrypts)
  end

  def health_answers_require_triage?
    health_answers.any? { it.response_yes? && it.would_require_triage? }
  end

  def who_responded
    if via_self_consent?
      "Child (Gillick competent)"
    else
      (parent_relationship || parent).label
    end
  end
end
