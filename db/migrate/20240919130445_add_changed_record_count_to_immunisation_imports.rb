# frozen_string_literal: true

class AddChangedRecordCountToImmunisationImports < ActiveRecord::Migration[7.2]
  def change
    add_column :immunisation_imports, :changed_record_count, :integer
  end
end
