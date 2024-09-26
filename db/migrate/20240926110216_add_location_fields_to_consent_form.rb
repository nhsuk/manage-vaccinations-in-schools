# frozen_string_literal: true

class AddLocationFieldsToConsentForm < ActiveRecord::Migration[7.2]
  def change
    add_column :consent_forms, :location_confirmed, :boolean
    add_reference :consent_forms, :location, foreign_key: true
  end
end
