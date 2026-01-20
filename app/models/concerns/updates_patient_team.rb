# frozen_string_literal: true

module UpdatesPatientTeam
  extend ActiveSupport::Concern

  included do
    after_save :update_patient_team
    after_destroy :update_patient_team
  end

  private

  def update_patient_team
    if should_update_patient_team?
      PatientTeamUpdater.call(
        patient_scope: patient_scope_for_update_patient_team,
        team_scope: team_scope_for_update_patient_team
      )
    end
  end

  def should_update_patient_team?
    try(:patient_id_previous_change).present? ||
      try(:team_id_previous_change).present?
  end

  def patient_scope_for_update_patient_team
    if (previous_change = try(:patient_id_previous_change)).present?
      Patient.where(id: previous_change.compact)
    end
  end

  def team_scope_for_update_patient_team
    if (previous_change = try(:team_id_previous_change)).present?
      Team.where(id: previous_change.compact)
    end
  end
end
