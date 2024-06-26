# frozen_string_literal: true

class CreateHealthQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :health_questions do |t|
      t.string :question

      t.references :vaccine, null: false, foreign_key: true

      t.timestamps
    end
  end
end
