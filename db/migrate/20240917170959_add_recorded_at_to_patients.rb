# frozen_string_literal: true

class AddRecordedAtToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :recorded_at, :datetime
  end
end
