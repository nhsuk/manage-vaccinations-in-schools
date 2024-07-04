# frozen_string_literal: true

class CreateImmunisationImports < ActiveRecord::Migration[7.1]
  def change
    create_table :immunisation_imports do |t|
      t.text :csv, null: false
      t.references :user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
