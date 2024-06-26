# frozen_string_literal: true

class AddReasonAndNotesToConsentForm < ActiveRecord::Migration[7.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.integer :reason
      t.text :reason_notes
    end
  end
end
