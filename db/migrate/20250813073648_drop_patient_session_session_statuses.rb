# frozen_string_literal: true

class DropPatientSessionSessionStatuses < ActiveRecord::Migration[8.0]
  def up
    drop_table :patient_session_session_statuses
  end
end
