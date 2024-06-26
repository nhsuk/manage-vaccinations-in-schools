# frozen_string_literal: true

class AddGillickCompetencyAssessorUserIdToPatientSessions < ActiveRecord::Migration[
  7.1
]
  def change
    add_reference :patient_sessions,
                  :gillick_competence_assessor_user,
                  foreign_key: {
                    to_table: :users
                  }
  end
end
