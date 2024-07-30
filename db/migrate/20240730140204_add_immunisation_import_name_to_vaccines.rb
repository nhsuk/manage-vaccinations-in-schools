# frozen_string_literal: true

class AddImmunisationImportNameToVaccines < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/NotNullColumn
  def change
    change_table :vaccines, bulk: true do |t|
      t.text :nivs_name, null: false
      t.index :nivs_name, unique: true
    end
  end
  # rubocop:enable Rails/NotNullColumn
end
