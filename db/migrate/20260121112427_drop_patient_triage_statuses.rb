# frozen_string_literal: true

class DropPatientTriageStatuses < ActiveRecord::Migration[8.1]
  def up
    drop_table :patient_triage_statuses
  end
end
