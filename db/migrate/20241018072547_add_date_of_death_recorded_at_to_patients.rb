# frozen_string_literal: true

class AddDateOfDeathRecordedAtToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :date_of_death_recorded_at, :datetime
  end
end
