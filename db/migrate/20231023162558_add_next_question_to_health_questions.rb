# frozen_string_literal: true

class AddNextQuestionToHealthQuestions < ActiveRecord::Migration[7.1]
  def change
    add_reference :health_questions,
                  :next_question,
                  null: true,
                  foreign_key: {
                    to_table: :health_questions
                  }
  end
end
