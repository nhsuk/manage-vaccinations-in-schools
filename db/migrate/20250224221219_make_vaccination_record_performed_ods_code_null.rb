# frozen_string_literal: true

class MakeVaccinationRecordPerformedODSCodeNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :vaccination_records, :performed_ods_code, true
  end
end
