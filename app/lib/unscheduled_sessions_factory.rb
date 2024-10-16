# frozen_string_literal: true

class UnscheduledSessionsFactory
  def initialize(academic_year: nil)
    @academic_year = academic_year || Date.current.academic_year
  end

  def call
    Team
      .includes(:locations, :programmes, :sessions)
      .find_each do |team|
        sessions = team.sessions.select { _1.academic_year == academic_year }

        team.locations.find_each do |location|
          next if sessions.any? { _1.location_id == location.id }

          programmes =
            team.programmes.select do
              _1.year_groups.intersect?(location.year_groups)
            end

          next if programmes.empty?

          Session.create!(academic_year:, location:, programmes:, team:).tap(
            &:create_patient_sessions!
          )
        end

        location_ids = team.locations.map(&:id)

        sessions
          .select(&:unscheduled?)
          .reject { _1.location_id.in?(location_ids) }
          .reject { _1.patients.exists? }
          .each(&:destroy!)
      end
  end

  private

  attr_reader :academic_year
end
