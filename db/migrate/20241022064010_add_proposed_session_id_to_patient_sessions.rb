# frozen_string_literal: true

class AddProposedSessionIdToPatientSessions < ActiveRecord::Migration[7.2]
  def change
    add_reference :patient_sessions,
                  :proposed_session,
                  foreign_key: {
                    to_table: :sessions
                  }
  end
end
