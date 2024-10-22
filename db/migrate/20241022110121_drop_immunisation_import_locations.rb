# frozen_string_literal: true

class DropImmunisationImportLocations < ActiveRecord::Migration[7.2]
  def up
    drop_join_table :immunisation_imports, :locations
  end

  def down
    create_join_table :immunisation_imports,
                      :locations,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[immunisation_import_id location_id], unique: true
    end
  end
end
