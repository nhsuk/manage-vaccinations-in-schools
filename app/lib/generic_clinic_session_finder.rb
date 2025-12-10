# frozen_string_literal: true

##
# This class can be used to find a suitable generic clinic session for a set
# of programmes.
class GenericClinicSessionFinder
  def initialize(team:, academic_year:, programmes:)
    @team = team
    @academic_year = academic_year
    @programmes = programmes
  end

  def call
    sessions_to_search =
      Session.joins(:team_location).where(
        team_location: {
          academic_year:,
          location:,
          team:
        }
      )

    sessions_to_search = sessions_to_search.has_any_programmes_of(programmes)

    sessions_to_search.find(&:scheduled?) ||
      sessions_to_search.find(&:unscheduled?) || sessions_to_search.first
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team, :academic_year, :programmes

  def location = team.generic_clinic
end
