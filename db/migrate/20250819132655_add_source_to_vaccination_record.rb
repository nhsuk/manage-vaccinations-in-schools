# frozen_string_literal: true

class AddSourceToVaccinationRecord < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records, :external_source, :integer
    VaccinationRecord.update_all(external_source: 0)
    VaccinationRecord.recorded_in_service.update_all(external_source: nil)
    add_check_constraint :vaccination_records,
                         "(session_id IS NULL AND external_source IS NOT NULL) OR " \
                           "(session_id IS NOT NULL AND external_source IS NULL)",
                         name: "external_source_check"
  end
end
