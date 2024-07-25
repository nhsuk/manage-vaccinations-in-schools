# frozen_string_literal: true

class AddDoseSequenceToVaccinationRecords < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :vaccination_records,
               :dose_sequence,
               :integer,
               null: false,
               default: 1
    change_column_default :vaccination_records, :dose_sequence, from: 1, to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
