# frozen_string_literal: true

class AddResponseToConsentForm < ActiveRecord::Migration[7.0]
  def change
    add_column :consent_forms, :response, :integer
  end
end
