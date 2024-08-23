# frozen_string_literal: true

class AddCountsToImmunisationImports < ActiveRecord::Migration[7.1]
  def change
    change_table :immunisation_imports, bulk: true do |t|
      t.integer :exact_duplicate_record_count
      t.integer :new_record_count
      t.integer :not_administered_record_count
    end
  end
end
