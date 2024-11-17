# frozen_string_literal: true

class RenameVaccinationRecordReasonToOutcome < ActiveRecord::Migration[7.2]
  def up
    rename_column :vaccination_records, :reason, :outcome
    VaccinationRecord
      .where.not(outcome: nil)
      .update_all("outcome = outcome + 1")
    VaccinationRecord.where(outcome: nil).update_all(outcome: 0)
    change_column_null :vaccination_records, :outcome, false
  end

  def down
    change_column_null :vaccination_records, :outcome, true
    VaccinationRecord.where(outcome: 0).update_all(outcome: nil)
    VaccinationRecord
      .where.not(outcome: nil)
      .update_all("outcome = outcome - 1")
    rename_column :vaccination_records, :outcome, :reason
  end
end
