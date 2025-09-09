# frozen_string_literal: true

class RemovePatientSessionFromPatientRegistrationStatuses < ActiveRecord::Migration[
  8.0
]
  def up
    change_table :patient_registration_statuses, bulk: true do |t|
      t.references :patient, foreign_key: { on_delete: :cascade }
      t.references :session, foreign_key: { on_delete: :cascade }
      t.index %i[patient_id session_id], unique: true
    end

    Patient::RegistrationStatus.find_each do |registration_status|
      patient_session =
        PatientSession.find(registration_status.patient_session_id)
      patient_id = patient_session.patient_id
      session_id = patient_session.session_id
      registration_status.update_columns(patient_id:, session_id:)
    end

    change_table :patient_registration_statuses, bulk: true do |t|
      t.change_null :patient_id, false
      t.change_null :session_id, false
      t.remove_references :patient_session
    end
  end

  def down
    change_table :patient_registration_statuses, bulk: true do |t|
      t.references :patient_session, foreign_key: { on_delete: :cascade }
      t.index :patient_session_id, unique: true
    end

    Patient::RegistrationStatus.find_each do |registration_status|
      patient_id = registration_status.patient_id
      session_id = registration_status.session_id
      patient_session = PatientSession.find_by!(patient_id:, session_id:)
      registration_status.update_column(:patient_session_id, patient_session.id)
    end

    change_table :patient_registration_statuses, bulk: true do |t|
      t.change_null :patient_session_id, false
      t.remove_references :patient, :session
    end
  end
end
