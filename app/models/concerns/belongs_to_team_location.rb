# frozen_string_literal: true

module BelongsToTeamLocation
  extend ActiveSupport::Concern

  included do
    self.ignored_columns = %w[team_id location_id academic_year]

    audited associated_with: :team_location
    has_associated_audits

    belongs_to :team_location

    has_one :team, through: :team_location
    has_one :location, through: :team_location
    has_one :subteam, through: :team_location

    delegate :academic_year, :location_id, :team_id, to: :team_location

    scope :for_team,
          ->(team) { joins(:team_location).where(team_location: { team: }) }

    scope :for_location,
          ->(location) do
            joins(:team_location).where(team_location: { location: })
          end

    scope :for_academic_year,
          ->(academic_year) do
            joins(:team_location).where(team_location: { academic_year: })
          end
  end
end
