# frozen_string_literal: true

class DataMigration::SetTeamLocation
  def call
    academic_year = AcademicYear.current

    team_locations =
      Location
        .includes(:subteam)
        .where.not(subteam_id: nil)
        .find_each
        .map do |location|
          location_id = location.id
          team_id = location.subteam.team_id

          # Clinics are visible to the whole team. The only reason clinics
          # had subteams before was because the data model required a
          # subteam to be set.
          subteam_id = (location.subteam_id if location.school?)

          TeamLocation.new(team_id:, academic_year:, location_id:, subteam_id:)
        end

    TeamLocation.import!(team_locations, on_duplicate_key_ignore: true)
  end

  def self.call(...) = new(...).call

  private_class_method :new
end
