# frozen_string_literal: true

class CreateConsentForms < ActiveRecord::Migration[7.0]
  def change
    create_table :consent_forms do |t|
      t.references :session, null: false, foreign_key: true

      t.datetime :recorded_at

      t.timestamps
    end
  end
end
