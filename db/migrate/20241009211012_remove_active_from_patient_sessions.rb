# frozen_string_literal: true

class RemoveActiveFromPatientSessions < ActiveRecord::Migration[7.2]
  def change
    remove_column :patient_sessions,
                  :active,
                  :boolean,
                  default: false,
                  null: false
  end
end
