# frozen_string_literal: true

class AddHealthAnswersToConsent < ActiveRecord::Migration[7.1]
  def change
    add_column :consents, :health_answers, :jsonb, null: false, default: []
  end
end
