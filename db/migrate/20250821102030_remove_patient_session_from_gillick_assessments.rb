# frozen_string_literal: true

class RemovePatientSessionFromGillickAssessments < ActiveRecord::Migration[8.0]
  def up
    change_table :gillick_assessments, bulk: true do |t|
      t.references :patient, foreign_key: true
      t.references :session_date, foreign_key: true
    end

    GillickAssessment.find_each.count do |gillick_assessment|
      patient_session =
        PatientSession.find(gillick_assessment.patient_session_id)
      patient_id = patient_session.patient_id
      session_id = patient_session.session_id
      session_date_id =
        SessionDate.find_by!(
          session_id:,
          value: gillick_assessment.created_at.to_date
        )
      gillick_assessment.update_columns(patient_id:, session_date_id:)
    end

    change_table :gillick_assessments, bulk: true do |t|
      t.change_null :patient_id, false
      t.change_null :session_date_id, false
      t.remove_references :patient_session
    end
  end

  def down
    add_reference :gillick_assessments, :patient_session

    GillickAssessment.find_each do |gillick_assessment|
      session_id =
        SessionDate.find(gillick_assessment.session_date_id).session_id
      patient_session =
        PatientSession.find_by!(
          patient_id: gillick_assessment.patient_id,
          session_id:
        )
      gillick_assessment.update_column(:patient_session_id, patient_session.id)
    end

    change_table :gillick_assessments, bulk: true do |t|
      t.change_null :patient_session_id, false
      t.remove_references :patient, :session_date
    end
  end
end
