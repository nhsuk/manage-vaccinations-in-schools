# frozen_string_literal: true

class ConsolidatedHealthAnswers
  def initialize(consents: nil)
    @answers = {}

    add_answers_from_consents(consents) if consents.present?
  end

  def add_answer(responder:, question:, answer:, notes: nil)
    @answers[question] ||= []
    @answers[question] << { responder:, answer:, notes: }
  end

  def add_answers_from_consent(consent)
    consent.health_answers.each do |health_question|
      add_answer(
        responder: consent.who_responded,
        question: health_question.question,
        answer: health_question.response.humanize.presence,
        notes: health_question.notes.presence
      )
    end
  end

  def add_answers_from_consents(consents)
    consents.each { add_answers_from_consent(_1) }
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
