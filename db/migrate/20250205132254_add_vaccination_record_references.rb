# frozen_string_literal: true

class AddVaccinationRecordReferences < ActiveRecord::Migration[8.0]
  def up
    change_table :vaccination_records, bulk: true do |t|
      t.references :patient, foreign_key: true
      t.references :session, foreign_key: true
      t.change_null :patient_session_id, null: true
    end

    VaccinationRecord.find_each do |vaccination_record|
      patient_session =
        PatientSession.find(vaccination_record.patient_session_id)
      vaccination_record.update!(
        patient_id: patient_session.patient_id,
        session_id: patient_session.session_id
      )
    end

    change_table :vaccination_records, bulk: true do |t|
      t.change_null :patient_id, null: false # rubocop:disable Rails/NotNullColumn
      t.remove_references :patient_session
    end
  end

  def down
    change_table :vaccination_records, bulk: true do |t|
      t.references :patient_session, foreign_key: true
      t.change_null :patient_id, null: true
    end

    VaccinationRecord.find_each do |vaccination_record|
      patient_session =
        PatientSession.find_by!(
          patient_id: vaccination_record.patient_id,
          session_id: vaccination_record.session_id
        )
      vaccination_record.update!(patient_session_id: patient_session.id)
    end

    change_table :vaccination_records, bulk: true do |t|
      t.change_null :patient_session_id, null: true
      t.remove_references :patient, :session
    end
  end
end
