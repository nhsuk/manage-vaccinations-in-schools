# frozen_string_literal: true

class AddReportedByAndReportedAtToVaccinationRecords < ActiveRecord::Migration[
  8.1
]
  def change
    add_reference :vaccination_records,
                  :reported_by,
                  foreign_key: {
                    to_table: :users
                  },
                  index: true
    add_column :vaccination_records, :reported_at, :datetime
  end
end
