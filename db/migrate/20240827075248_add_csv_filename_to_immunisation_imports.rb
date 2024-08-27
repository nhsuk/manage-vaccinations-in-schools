# frozen_string_literal: true

class AddCSVFilenameToImmunisationImports < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :immunisation_imports,
               :csv_filename,
               :text,
               null: false,
               default: ""

    change_column_default :immunisation_imports,
                          :csv_filename,
                          from: "",
                          to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
