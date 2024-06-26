# frozen_string_literal: true

class RemoveUnusedFieldsFromPatient < ActiveRecord::Migration[7.1]
  def up
    change_table :patients, bulk: true do |t|
      t.remove :consent, :screening, :seen, :parent_info_source, :sex
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
