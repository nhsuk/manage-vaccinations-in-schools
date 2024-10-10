# frozen_string_literal: true

class RemoveCreatedByUserFromPatientSessions < ActiveRecord::Migration[7.2]
  def change
    remove_reference :patient_sessions,
                     :created_by_user,
                     foreign_key: {
                       to_table: :users
                     }
  end
end
