# frozen_string_literal: true

class RemovePatientSessionFromPreScreenings < ActiveRecord::Migration[8.0]
  def up
    change_table :pre_screenings, bulk: true do |t|
      t.references :patient, foreign_key: true
      t.references :session_date, foreign_key: true
    end

    PreScreening.find_each do |pre_screening|
      patient_session = PatientSession.find(pre_screening.patient_session_id)
      patient_id = patient_session.patient_id
      session_id = patient_session.session_id
      session_date_id =
        SessionDate.find_by!(
          session_id:,
          value: pre_screening.created_at.to_date
        )
      pre_screening.update_columns(patient_id:, session_date_id:)
    end

    change_table :pre_screenings, bulk: true do |t|
      t.change_null :patient_id, false
      t.change_null :session_date_id, false
      t.remove_references :patient_session
    end
  end

  def down
    add_reference :pre_screenings, :patient_session

    PreScreening.find_each do |pre_screening|
      session_id = SessionDate.find(pre_screening.session_date_id).session_id
      patient_session =
        PatientSession.find_by!(
          patient_id: pre_screening.patient_id,
          session_id:
        )
      pre_screening.update_column(:patient_session_id, patient_session.id)
    end

    change_table :pre_screenings, bulk: true do |t|
      t.change_null :patient_session_id, false
      t.remove_references :patient, :session_date
    end
  end
end
