# frozen_string_literal: true

class AddUnusedColumnOnPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :unused_column, :string
  end
end
