# frozen_string_literal: true

class ReplaceTriagePatientSessionWithPatientAndTeam < ActiveRecord::Migration[
  7.2
]
  def up
    change_table :triage, bulk: true do |t|
      t.references :patient, foreign_key: true
      t.references :team, foreign_key: true
    end

    Triage.find_each do |triage|
      patient_session =
        PatientSession.includes(:session).find(triage.patient_session_id)

      triage.update!(
        team_id: patient_session.session.team_id,
        patient_id: patient_session.patient_id
      )
    end

    change_table :triage, bulk: true do |t|
      t.change_null :patient_id, false
      t.change_null :team_id, false
    end

    remove_reference :triage, :patient_session
  end

  # Not reversible as we lose track of the patient sessions
end
