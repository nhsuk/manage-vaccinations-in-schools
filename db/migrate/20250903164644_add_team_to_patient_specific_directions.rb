# frozen_string_literal: true

class AddTeamToPatientSpecificDirections < ActiveRecord::Migration[8.0]
  def change
    add_reference :patient_specific_directions, :team, foreign_key: true

    reversible do |dir|
      dir.up do
        PatientSpecificDirection
          .includes(patient: :teams)
          .find_each do |psd|
            team_id = psd.patient.teams.first.id
            psd.update_column(:team_id, team_id)
          end
      end
    end

    change_column_null :patient_specific_directions, :team_id, false
  end
end
