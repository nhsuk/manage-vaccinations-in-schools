# frozen_string_literal: true

class TeamSessionsFactory
  def initialize(team, academic_year:, sync_patient_teams_now: false)
    @team = team
    @academic_year = academic_year
    @sync_patient_teams_now = sync_patient_teams_now
  end

  def call
    ActiveRecord::Base.transaction do
      team_locations.find_each do |team_location|
        TeamLocationSessionsFactory.call(team_location, sync_patient_teams_now:)
      end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team, :academic_year, :sync_patient_teams_now

  def team_locations
    TeamLocation.where(team:, academic_year:).includes(:location)
  end
end
