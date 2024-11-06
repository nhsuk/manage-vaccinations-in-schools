# frozen_string_literal: true

class RemoveUnusedColumnOnPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :unused_column, :string
  end
end
