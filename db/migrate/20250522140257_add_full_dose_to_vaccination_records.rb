# frozen_string_literal: true

class AddFullDoseToVaccinationRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records, :full_dose, :boolean

    reversible do |dir|
      dir.up { VaccinationRecord.administered.update_all(full_dose: true) }
    end
  end
end
