# frozen_string_literal: true

class AddIgnoredRecordCountToImmunisationImport < ActiveRecord::Migration[8.1]
  def change
    add_column :immunisation_imports, :ignored_record_count, :integer

    reversible do |dir|
      dir.up do
        ImmunisationImport.processed.update_all(ignored_record_count: 0)
      end
    end
  end
end
