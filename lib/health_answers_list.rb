class HealthAnswersList
  include Enumerable

  def initialize(health_answers = nil)
    @health_answers = health_answers || []
  end

  def each
    return if @health_answers.empty?

    ha = @health_answers.first
    loop do
      yield ha
      break unless ha.next_question
      ha = @health_answers.find { |new_ha| new_ha.id == ha.next_question.to_i }
    end
  end

  delegate :[], to: :to_a
end
