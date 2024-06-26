# frozen_string_literal: true

class AddMetadataToHealthQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :health_questions, :metadata, :jsonb, null: false, default: {}
  end
end
