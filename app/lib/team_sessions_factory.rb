# frozen_string_literal: true

class TeamSessionsFactory
  def initialize(team, academic_year:)
    @team = team
    @academic_year = academic_year
  end

  def call
    create_missing_sessions!
    destroy_orphaned_sessions!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team, :academic_year

  def create_missing_sessions!
    ActiveRecord::Base.transaction do
      team
        .locations
        .includes(:team, :programmes)
        .find_each { LocationSessionsFactory.call(it, academic_year:) }
    end
  end

  def destroy_orphaned_sessions!
    ActiveRecord::Base.transaction do
      team
        .sessions
        .includes(:location, :session_programmes)
        .unscheduled
        .where(academic_year:)
        .where.not(location: team.locations)
        .where
        .missing(:patient_sessions)
        .destroy_all
    end
  end
end
