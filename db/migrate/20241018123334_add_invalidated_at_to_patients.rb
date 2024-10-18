# frozen_string_literal: true

class AddInvalidatedAtToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :invalidated_at, :datetime
  end
end
