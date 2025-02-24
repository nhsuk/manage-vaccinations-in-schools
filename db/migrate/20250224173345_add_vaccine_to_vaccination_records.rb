# frozen_string_literal: true

class AddVaccineToVaccinationRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :vaccination_records, :vaccine, foreign_key: true

    reversible do |dir|
      dir.up do
        VaccinationRecord
          .where.not(batch_id: nil)
          .eager_load(:batch)
          .find_each { it.update_column(:vaccine_id, it.batch.vaccine_id) }
      end
    end
  end
end
