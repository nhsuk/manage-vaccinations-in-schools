# frozen_string_literal: true

class AddLocationToVaccinationRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :vaccination_records, :location

    reversible do |dir|
      dir.up do
        VaccinationRecord
          .where.not(session_id: nil)
          .eager_load(:session)
          .find_each { it.update_column(:location_id, it.session.location_id) }
      end
    end
  end
end
