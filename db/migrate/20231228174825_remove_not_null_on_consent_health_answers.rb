# frozen_string_literal: true

class RemoveNotNullOnConsentHealthAnswers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :consents, :health_answers, true
  end
end
