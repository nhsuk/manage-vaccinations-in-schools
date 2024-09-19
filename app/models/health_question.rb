# frozen_string_literal: true

# == Schema Information
#
# Table name: health_questions
#
#  id                    :bigint           not null, primary key
#  hint                  :string
#  metadata              :jsonb            not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  follow_up_question_id :bigint
#  next_question_id      :bigint
#  vaccine_id            :bigint           not null
#
# Indexes
#
#  index_health_questions_on_follow_up_question_id  (follow_up_question_id)
#  index_health_questions_on_next_question_id       (next_question_id)
#  index_health_questions_on_vaccine_id             (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (follow_up_question_id => health_questions.id)
#  fk_rails_...  (next_question_id => health_questions.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class HealthQuestion < ApplicationRecord
  attr_accessor :response, :notes

  belongs_to :vaccine
  belongs_to :next_question, optional: true, class_name: "HealthQuestion"
  belongs_to :follow_up_question, optional: true, class_name: "HealthQuestion"

  def self.first_health_question
    question_ids, next_question_ids, follow_up_question_ids =
      pluck(:id, :next_question_id, :follow_up_question_id).transpose
    id_set = question_ids - next_question_ids - follow_up_question_ids

    raise "No first question found" if id_set.empty?
    raise "More than one first question found" if id_set.length > 1

    find id_set.first
  end

  def self.last_health_question
    question = first_health_question
    question = question.next_question until question.next_question.nil?
    question
  end

  def self.in_order
    first_health_question.remaining_questions
  end

  def self.to_health_answers
    HealthAnswer.from_health_questions(in_order)
  end

  # Turn the health questions into an array ordered by follow_up_questions and
  # next_questions.
  def remaining_questions(ary = nil)
    ary ||= []
    ary << self

    follow_up_question.remaining_questions(ary) if follow_up_question.present?
    if next_question.present? && !next_question.in?(ary)
      next_question.remaining_questions(ary)
    end

    ary
  end
end
