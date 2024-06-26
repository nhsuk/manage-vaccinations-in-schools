# frozen_string_literal: true

class HealthAnswer
  include ActiveModel::Model

  attr_accessor :id,
                :question,
                :response,
                :notes,
                :hint,
                :next_question,
                :follow_up_question

  validates :notes, length: { maximum: 1000 }

  validates :response, presence: true, inclusion: { in: %w[yes no] }
  validates :notes, presence: true, if: -> { response == "yes" }

  def attributes
    %i[
      id
      question
      response
      notes
      hint
      next_question
      follow_up_question
    ].index_with { |attr| send(attr) }
  end

  def next_health_answer_index
    if response == "no"
      next_question
    else
      follow_up_question || next_question
    end
  end

  def assign_attributes(attrs)
    attrs = attrs.except("notes") if attrs["response"] == "no"
    super(attrs)
  end

  def self.from_health_questions(health_questions)
    hq_id_map = Hash[health_questions.map.with_index { |hq, i| [hq.id, i] }]

    health_questions.map do |hq|
      new id: hq_id_map[hq.id],
          question: hq.question,
          response: nil,
          notes: nil,
          hint: hq.hint,
          next_question: hq_id_map[hq.next_question_id],
          follow_up_question: hq_id_map[hq.follow_up_question_id]
    end
  end

  class ArraySerializer
    def self.load(arr)
      return if arr.nil?
      arr.map.with_index { |(item), idx| HealthAnswer.new(item.merge(id: idx)) }
    end

    def self.dump(value)
      value.map(&:attributes)
    end
  end
end
