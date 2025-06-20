# frozen_string_literal: true

class CreateIdentityChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :identity_checks do |t|
      t.boolean :confirmed_by_patient, null: false
      t.string :confirmed_by_other_name, null: false, default: ""
      t.string :confirmed_by_other_relationship, null: false, default: ""
      t.references :vaccination_record,
                   null: false,
                   foreign_key: {
                     on_delete: :cascade
                   }
      t.timestamps
    end
  end
end
