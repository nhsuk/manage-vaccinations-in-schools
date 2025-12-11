# frozen_string_literal: true

class AddIgnoredRecordCountToImmunisationImport < ActiveRecord::Migration[8.1]
  def change
    add_column :immunisation_imports, :ignored_record_count, :integer
  end
end
