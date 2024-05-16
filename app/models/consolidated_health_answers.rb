class ConsolidatedHealthAnswers
  def initialize
    @answers = {}
  end

  def add_answer(responder:, question:, answer:, notes: nil)
    @answers[question] ||= []
    @answers[question] << { responder:, answer:, notes: }
  end

  # Produces responses in the format:
  # {
  #   "Question 1" => [
  #     { responder: "All", answer: "No" }, # if both Person 1 and Person 2 answered No to Question 1
  #   ],
  #   "Question 2" => [
  #     { responder: "Person 1", answer: "No" },
  #     { responder: "Person 2", answer: "Yes", notes: "Some notes" }
  #   ]
  # }
  def to_h
    consolidated_answers
  end

  private

  def consolidated_answers
    @answers.transform_values { |answers| consolidate_answers(answers) }
  end

  def consolidate_answers(answers)
    if answers.length > 1 && same_answer_and_notes_for_all?(answers)
      [answers.first.merge(responder: "All")]
    else
      answers
    end
  end

  def same_answer_and_notes_for_all?(answers)
    answers.uniq { |a| [a[:answer], a[:notes]] }.length == 1
  end
end
