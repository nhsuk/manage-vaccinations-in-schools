# frozen_string_literal: true

class AddCreatedByToPatientSession < ActiveRecord::Migration[7.1]
  def change
    add_reference :patient_sessions,
                  :created_by_user,
                  foreign_key: {
                    to_table: :users
                  }
  end
end
