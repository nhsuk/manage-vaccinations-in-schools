# frozen_string_literal: true

class AddRecordedAtToConsentResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :consent_responses, :recorded_at, :datetime
  end
end
