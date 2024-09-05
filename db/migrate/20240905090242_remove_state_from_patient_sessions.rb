# frozen_string_literal: true

class RemoveStateFromPatientSessions < ActiveRecord::Migration[7.2]
  def change
    remove_column :patient_sessions, :state, :string
  end
end
