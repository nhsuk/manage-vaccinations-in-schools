# frozen_string_literal: true

class AddProcessedAtToImmunisationImports < ActiveRecord::Migration[7.1]
  def change
    add_column :immunisation_imports, :processed_at, :datetime
  end
end
