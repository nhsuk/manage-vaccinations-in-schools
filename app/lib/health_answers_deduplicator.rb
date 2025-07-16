# frozen_string_literal: true

class HealthAnswersDeduplicator
  def initialize(vaccines:)
    @vaccines = vaccines
  end

  def call
    @health_answers = []

    vaccines.each { |vaccine| add_unique_health_answers(vaccine) }

    re_map_question_indexes
    fill_in_next_question_gaps

    @health_answers
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccines

  def add_unique_health_answers(vaccine)
    vaccine_health_answers = vaccine.health_questions.to_health_answers

    vaccine_health_answers.deep_dup.each do |health_answer|
      existing_index = existing_question_index(health_answer.question)

      # This doesn't work very well if the question already exists but is
      # otherwise different, for example if the followup question is
      # different. We don't have instances of this currently.

      next unless existing_index.nil?

      health_answer.id = @health_answers.length

      # We store the questions here and re-map them to indexes later when we
      # know what all the questions will be.

      if (index = health_answer.next_question).present?
        health_answer.next_question =
          find_new_next_question(vaccine_health_answers, index)
      end

      if (index = health_answer.follow_up_question).present?
        health_answer.follow_up_question =
          find_new_follow_up_question(vaccine_health_answers, index)
      end

      @health_answers << health_answer
    end
  end

  def find_new_next_question(vaccine_health_answers, index)
    loop do
      health_answer_to_check = vaccine_health_answers.find { it.id == index }
      break if health_answer_to_check.nil?

      if existing_question_index(health_answer_to_check.question).nil?
        break health_answer_to_check.question
      end

      index = health_answer_to_check.next_question
    end
  end

  def find_new_follow_up_question(vaccine_health_answers, index)
    vaccine_health_answers.find { it.id == index }.question
  end

  def existing_question_index(question)
    @health_answers.index { it.question == question }
  end

  def re_map_question_indexes
    @health_answers.each do |health_answer|
      if (question = health_answer.next_question)
        health_answer.next_question = existing_question_index(question)
      end

      if (question = health_answer.follow_up_question)
        health_answer.follow_up_question = existing_question_index(question)
      end
    end
  end

  def fill_in_next_question_gaps
    @health_answers.each_with_index do |health_answer, index|
      if health_answer.next_question.nil? && index < @health_answers.length - 1
        health_answer.next_question = index + 1
      end
    end
  end
end
