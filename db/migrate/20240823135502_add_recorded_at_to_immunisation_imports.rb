# frozen_string_literal: true

class AddRecordedAtToImmunisationImports < ActiveRecord::Migration[7.1]
  def change
    add_column :immunisation_imports, :recorded_at, :datetime
  end
end
