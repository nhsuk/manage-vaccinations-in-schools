# frozen_string_literal: true

class MakeVaccinationRecordDoseSequenceNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :vaccination_records, :dose_sequence, true
  end
end
