# frozen_string_literal: true

class AddNameToConsentForm < ActiveRecord::Migration[7.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.text :first_name
      t.text :last_name
      t.boolean :use_common_name
      t.text :common_name
    end
  end
end
