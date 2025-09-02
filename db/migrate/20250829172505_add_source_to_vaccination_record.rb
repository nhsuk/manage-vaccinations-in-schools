# frozen_string_literal: true

class AddSourceToVaccinationRecord < ActiveRecord::Migration[8.0]
  def up
    add_column :vaccination_records, :source, :integer

    VaccinationRecord.update_all(source: "historical_upload")
    # This handles records which were created when a parent refused consent because the patient was already vaccinated
    consent_refusal_vaccination_records =
      VaccinationRecord
        .includes(:immunisation_imports)
        .where(outcome: "already_had")
        .select { |record| record.immunisation_imports.empty? }

    if consent_refusal_vaccination_records.any?
      VaccinationRecord.where(
        id: consent_refusal_vaccination_records.map(&:id)
      ).update_all(source: "consent_refusal")
    end
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
