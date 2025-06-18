# frozen_string_literal: true

class AddGiveDetailsHintToHealthQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :health_questions, :give_details_hint, :string
  end
end
