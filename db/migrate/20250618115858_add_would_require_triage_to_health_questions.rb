# frozen_string_literal: true

class AddWouldRequireTriageToHealthQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :health_questions,
               :would_require_triage,
               :boolean,
               default: true,
               null: false
  end
end
