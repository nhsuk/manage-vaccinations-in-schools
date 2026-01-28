# frozen_string_literal: true

class DropPatientConsentStatuses < ActiveRecord::Migration[8.1]
  def up
    drop_table :patient_consent_statuses
  end
end
