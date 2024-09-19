# frozen_string_literal: true

class RenameHealthQuestionsQuestion < ActiveRecord::Migration[7.2]
  def change
    change_table :health_questions, bulk: true do |t|
      t.change_null :question, false
      t.rename :question, :title
    end
  end
end
