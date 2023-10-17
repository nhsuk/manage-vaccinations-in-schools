require "health_answers_list"

class HealthAnswer
  include ActiveModel::Model

  attr_accessor :id, :question, :response, :notes, :hint, :next_question

  validates :response, presence: true, inclusion: { in: %w[yes no] }
  validates :notes, presence: true, if: -> { response == "yes" }

  def attributes
    %i[id question response notes hint next_question].index_with do |attr|
      send(attr)
    end
  end

  class ListSerializer
    def self.load(arr)
      HealthAnswersList.new(arr&.map { |item| HealthAnswer.new(item) })
    end

    def self.dump(value)
      value.map(&:attributes)
    end
  end
end
