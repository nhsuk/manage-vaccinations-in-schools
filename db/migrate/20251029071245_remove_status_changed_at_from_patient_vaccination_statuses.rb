# frozen_string_literal: true

class RemoveStatusChangedAtFromPatientVaccinationStatuses < ActiveRecord::Migration[
  8.0
]
  def change
    remove_column :patient_vaccination_statuses, :status_changed_at, :datetime
  end
end
