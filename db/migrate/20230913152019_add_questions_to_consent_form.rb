# frozen_string_literal: true

class AddQuestionsToConsentForm < ActiveRecord::Migration[7.0]
  def change
    add_column :consent_forms, :health_answers, :jsonb, null: false, default: []
  end
end
