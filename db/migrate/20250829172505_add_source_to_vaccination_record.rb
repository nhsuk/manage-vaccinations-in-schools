# frozen_string_literal: true

class AddSourceToVaccinationRecord < ActiveRecord::Migration[8.0]
  def up
    add_column :vaccination_records, :source, :integer

    # Backfill values based on presence of session_id
    VaccinationRecord.update_all(source: "historical_upload")
    VaccinationRecord.where(outcome: "already_had").update_all(
      source: "consent_refusal"
    )
    VaccinationRecord.recorded_in_service.update_all(source: "service")

    change_column_null :vaccination_records, :source, false
    add_check_constraint :vaccination_records,
                         "(session_id IS NULL AND source != 0) OR " \
                           "(session_id IS NOT NULL AND source = 0)",
                         name: "source_check"
  end

  def down
    remove_check_constraint :vaccination_records, name: "source_check"
    remove_column :vaccination_records, :source, :integer
  end
end
