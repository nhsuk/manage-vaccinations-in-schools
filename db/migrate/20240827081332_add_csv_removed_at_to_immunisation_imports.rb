# frozen_string_literal: true

class AddCSVRemovedAtToImmunisationImports < ActiveRecord::Migration[7.1]
  def change
    change_table :immunisation_imports, bulk: true do |t|
      t.datetime :csv_removed_at
      t.change_null :csv_data, true
    end
  end
end
