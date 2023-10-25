class HealthAnswer
  include ActiveModel::Model

  attr_accessor :id,
                :question,
                :response,
                :notes,
                :hint,
                :next_question,
                :follow_up_question

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

  class ArraySerializer
    def self.load(arr)
      return [] if arr.nil?
      arr.map { |item| HealthAnswer.new(item) }
    end

    def self.dump(value)
      value.map(&:attributes)
    end
  end
end
