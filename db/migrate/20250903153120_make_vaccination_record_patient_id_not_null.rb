# frozen_string_literal: true

class MakeVaccinationRecordPatientIdNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :vaccination_records, :patient_id, false
  end
end
