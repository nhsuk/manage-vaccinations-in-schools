# frozen_string_literal: true

class AddHealthQuestionsToConsentResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :consent_responses, :health_questions, :jsonb
  end
end
