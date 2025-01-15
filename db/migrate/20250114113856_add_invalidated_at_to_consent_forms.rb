# frozen_string_literal: true

class AddInvalidatedAtToConsentForms < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_forms, :invalidated_at, :datetime
  end
end
