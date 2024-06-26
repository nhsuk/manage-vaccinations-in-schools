# frozen_string_literal: true

class AddIdToPatientSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :patient_sessions, :id, :primary_key
  end
end
