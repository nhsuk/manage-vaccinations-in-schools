# frozen_string_literal: true

class AddFollowUpQuestionToHealthQuestions < ActiveRecord::Migration[7.0]
  def change
    add_reference :health_questions,
                  :follow_up_question,
                  null: true,
                  foreign_key: {
                    to_table: :health_questions
                  }
  end
end
