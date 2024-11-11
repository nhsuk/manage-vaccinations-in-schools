# frozen_string_literal: true

class RemoveNotAdministeredRecordCountFromImmunisationImports < ActiveRecord::Migration[
  7.2
]
  def change
    remove_column :immunisation_imports,
                  :not_administered_record_count,
                  :integer
  end
end
