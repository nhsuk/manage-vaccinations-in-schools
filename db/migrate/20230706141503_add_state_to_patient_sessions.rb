# frozen_string_literal: true

class AddStateToPatientSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :patient_sessions, :state, :string
  end
end
