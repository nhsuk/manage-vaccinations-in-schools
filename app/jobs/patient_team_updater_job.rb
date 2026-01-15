# frozen_string_literal: true

class PatientTeamUpdaterJob
  include Sidekiq::Job

  sidekiq_options queue: :cache, lock: :until_executed

  def perform(patient_id = nil, team_id = nil)
    patient_scope = (patient_id ? Patient.where(id: patient_id) : nil)
    team_scope = (team_id ? Team.where(id: team_id) : nil)
    PatientTeamUpdater.call(patient_scope:, team_scope:)
  end
end
