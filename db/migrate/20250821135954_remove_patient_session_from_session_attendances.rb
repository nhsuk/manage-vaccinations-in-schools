# frozen_string_literal: true

class RemovePatientSessionFromSessionAttendances < ActiveRecord::Migration[8.0]
  def up
    change_table :session_attendances, bulk: true do |t|
      t.references :patient, foreign_key: true
      t.index %i[patient_id session_date_id], unique: true
    end

    SessionAttendance.find_each do |session_attendance|
      patient_session =
        PatientSession.find(session_attendance.patient_session_id)
      patient_id = patient_session.patient_id
      session_attendance.update_column(:patient_id, patient_id)
    end

    change_table :session_attendances, bulk: true do |t|
      t.change_null :patient_id, false
      t.remove_references :patient_session
    end
  end

  def down
    add_reference :session_attendances, :patient_session

    SessionAttendance.find_each do |session_attendance|
      session_id =
        SessionDate.find(session_attendance.session_date_id).session_id
      patient_session =
        PatientSession.find_by!(
          patient_id: session_attendance.patient_id,
          session_id:
        )
      session_attendance.update_column(:patient_session_id, patient_session.id)
    end

    change_table :session_attendances, bulk: true do |t|
      t.change_null :patient_session_id, false
      t.remove_references :patient
    end
  end
end
