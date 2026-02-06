# frozen_string_literal: true

class AddEthnicityAttributesToConsentForms < ActiveRecord::Migration[8.1]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.integer :ethnic_group
      t.integer :ethnic_background
      t.string :ethnic_background_other
    end
  end
end
