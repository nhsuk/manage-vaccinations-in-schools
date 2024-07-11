# frozen_string_literal: true

class AddImportedFromToVaccinationRecords < ActiveRecord::Migration[7.1]
  def change
    add_reference :vaccination_records,
                  :imported_from,
                  foreign_key: {
                    to_table: :immunisation_imports
                  }
  end
end
