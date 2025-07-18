# frozen_string_literal: true

class UnscheduledSessionsFactory
  def initialize(academic_year: nil)
    @academic_year = academic_year || AcademicYear.current
  end

  def call
    Organisation
      .includes(
        :locations,
        :programmes,
        :sessions,
        locations: :programme_year_groups
      )
      .find_each do |organisation|
        sessions =
          organisation.sessions.select { it.academic_year == academic_year }

        organisation.locations.find_each do |location|
          next if sessions.any? { it.location_id == location.id }

          programmes =
            if location.generic_clinic?
              organisation.programmes
            elsif location.school?
              organisation.programmes.select do |programme|
                location.programme_year_groups.any? do
                  it.programme_id == programme.id &&
                    it.year_group.in?(location.year_groups)
                end
              end
            else
              [] # don't create sessions for unhandled location types
            end

          next if programmes.empty?

          Session.create!(academic_year:, location:, programmes:, organisation:)
        end

        location_ids = organisation.locations.map(&:id)

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
