# frozen_string_literal: true

class DropPatientVaccinationStatuses < ActiveRecord::Migration[8.1]
  def up
    drop_table :patient_vaccination_statuses
  end
end
