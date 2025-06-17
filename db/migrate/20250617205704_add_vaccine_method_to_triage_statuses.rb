# frozen_string_literal: true

class AddVaccineMethodToTriageStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :patient_triage_statuses, :vaccine_method, :integer
  end
end
