# frozen_string_literal: true

class DropTableBatchesImmunisationImports < ActiveRecord::Migration[8.1]
  def change
    drop_table :batches_immunisation_imports do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :immunisation_import, null: false, foreign_key: true
    end
  end
end
