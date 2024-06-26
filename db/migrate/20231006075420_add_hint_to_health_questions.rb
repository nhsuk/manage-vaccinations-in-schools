# frozen_string_literal: true

class AddHintToHealthQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :health_questions, :hint, :string
  end
end
