# frozen_string_literal: true

class AddDateOfBirthToConsentForm < ActiveRecord::Migration[7.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.date :date_of_birth
    end
  end
end
