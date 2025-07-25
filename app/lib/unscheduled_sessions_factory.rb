# frozen_string_literal: true

class UnscheduledSessionsFactory
  def initialize(academic_year: nil)
    @academic_year = academic_year || AcademicYear.current
  end

  def call
    Team.find_each { handle_team!(it) }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :academic_year

  def handle_team!(team)
    create_sessions_for_all_programmes!(team.locations.generic_clinic)
    create_sessions_per_programme_group!(team.locations.school)

    destroy_orphaned_sessions!(team)
  end

  def create_sessions_for_all_programmes!(locations)
    locations
      .includes(:team, :programmes)
      .find_each do |location|
        team = location.team
        programmes = location.programmes.reorder(nil)

        if team
             .sessions
             .has_programmes(programmes)
             .exists?(academic_year:, location:)
          next
        end

        team.sessions.create!(academic_year:, location:, programmes:)
      end
  end

  def create_sessions_per_programme_group!(locations)
    locations
      .includes(:team, :programmes)
      .find_each do |location|
        team = location.team

        ProgrammeGrouper
          .call(location.programmes)
          .each_value do |programmes|
            if team
                 .sessions
                 .has_programmes(programmes)
                 .exists?(academic_year:, location:)
              next
            end

            team.sessions.create!(academic_year:, location:, programmes:)
          end
      end
  end

  def destroy_orphaned_sessions!(team)
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
