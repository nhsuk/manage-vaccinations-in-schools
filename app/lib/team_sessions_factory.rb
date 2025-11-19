# frozen_string_literal: true

class TeamSessionsFactory
  def initialize(team, academic_year:, sync_patient_teams_now: false)
    @team = team
    @academic_year = academic_year
    @sync_patient_teams_now = sync_patient_teams_now
  end

  def call
    create_missing_sessions!
    destroy_orphaned_sessions!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team, :academic_year, :sync_patient_teams_now

  def create_missing_sessions!
    ActiveRecord::Base.transaction do
      team
        .team_locations
        .where(academic_year:)
        .includes(location: :location_programme_year_groups)
        .find_each do |team_location|
          TeamLocationSessionsFactory.call(
            team_location,
            sync_patient_teams_now:
          )
        end
    end
  end

  def destroy_orphaned_sessions!
    ActiveRecord::Base.transaction do
      team
        .sessions
        .includes(:location, :session_programme_year_groups, :team_location)
        .unscheduled
        .where(academic_year:)
        .where.not(location: team.locations)
        .find_each { |session| session.destroy! if session.patients.empty? }
    end
  end
end
