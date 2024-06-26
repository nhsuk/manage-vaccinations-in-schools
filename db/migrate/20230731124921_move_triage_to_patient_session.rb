# frozen_string_literal: true

class MoveTriageToPatientSession < ActiveRecord::Migration[7.0]
  def up
    Triage.all.find_each do |triage|
      ps =
        PatientSession.find_by! patient_id: triage.patient_id,
                                session_id:
                                  Session.find_by(
                                    campaign_id: triage.campaign_id
                                  ).id
      triage.patient_session_id = ps.id
      triage.save!
    end
  end

  def down
    Triage.all.find_each do |triage|
      triage.patient_id =
        PatientSession.find(triage.patient_session_id).patient_id
      triage.campaign_id =
        PatientSession.find(triage.patient_session_id).session.campaign_id
      triage.save!
    end
  end
end
