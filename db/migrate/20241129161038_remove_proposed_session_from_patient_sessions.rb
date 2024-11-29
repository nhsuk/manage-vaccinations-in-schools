# frozen_string_literal: true

class RemoveProposedSessionFromPatientSessions < ActiveRecord::Migration[7.2]
  def change
    remove_reference :patient_sessions,
                     :proposed_session,
                     foreign_key: {
                       to_table: :sessions
                     }
  end
end
