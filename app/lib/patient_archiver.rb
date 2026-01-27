# frozen_string_literal: true

class PatientArchiver
  def initialize(patient:, team:, type:, user: nil, other_details: nil)
    @patient = patient
    @team = team
    @user = user
    @type = type
    @other_details = other_details
  end

  def call
    ActiveRecord::Base.transaction do
      if type == "other"
        archive_reason.update!(type:, other_details:)
      else
        archive_reason.update!(type:, other_details: "")
      end

      patient.clear_pending_sessions!(team:)

      destroy_school_moves!

      update_patient_teams!
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient, :team, :type, :other_details

  def archive_reason
    @archive_reason ||=
      ArchiveReason.find_or_create_by(team:, patient:, created_by: @user)
  end

  def destroy_school_moves!
    patient.school_moves.where(team:).destroy_all

    patient
      .school_moves
      .joins_team_locations_for_school
      .where("team_locations.team_id = ?", team.id)
      .destroy_all
  end

  def update_patient_teams!
    PatientTeamUpdater.call(
      patient_scope: Patient.where(id: patient.id),
      team_scope: Team.where(id: team.id)
    )
  end
end
