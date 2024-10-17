# frozen_string_literal: true

class RemoveRecordedAtFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :recorded_at, :datetime
  end
end
