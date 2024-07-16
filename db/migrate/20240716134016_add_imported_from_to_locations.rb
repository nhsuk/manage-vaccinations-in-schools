# frozen_string_literal: true

class AddImportedFromToLocations < ActiveRecord::Migration[7.1]
  def change
    add_reference :locations,
                  :imported_from,
                  foreign_key: {
                    to_table: :immunisation_imports
                  }
  end
end
