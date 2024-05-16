class ConsolidatedHealthAnswers
  def initialize
    @answers = {}
  end

  def add_answer(responder:, question:, answer:, notes: nil)
    @answers[question] ||= []
    @answers[question] << { responder:, answer:, notes: }
  end

  def to_h
    consolidated_answers
  end

  private

  def consolidated_answers
    @answers.transform_values { |answers| consolidate_answers(answers) }
  end

  def consolidate_answers(answers)
    if answers.length == 1
      answers
    elsif answers.uniq { |a| [a[:answer], a[:notes]] }.length == 1
      [answers.first.merge(responder: "All")]
    else
      answers
    end
  end
end
