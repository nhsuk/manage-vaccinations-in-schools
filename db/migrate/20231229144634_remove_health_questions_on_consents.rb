# frozen_string_literal: true

class RemoveHealthQuestionsOnConsents < ActiveRecord::Migration[7.1]
  def change
    remove_column :consents, :health_questions, :jsonb
  end
end
