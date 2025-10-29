# frozen_string_literal: true

class AddLatestDateToPatientVaccinationStatuses < ActiveRecord::Migration[8.0]
  def change
    change_table :patient_vaccination_statuses, bulk: true do |t|
      t.date :latest_date
      t.change_null :status_changed_at, true
    end
  end
end
