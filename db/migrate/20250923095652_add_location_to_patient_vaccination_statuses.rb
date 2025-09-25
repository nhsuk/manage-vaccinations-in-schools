# frozen_string_literal: true

class AddLocationToPatientVaccinationStatuses < ActiveRecord::Migration[8.0]
  def change
    add_reference :patient_vaccination_statuses,
                  :latest_location,
                  foreign_key: {
                    to_table: :locations
                  }
  end
end
