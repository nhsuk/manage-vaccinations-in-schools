# frozen_string_literal: true

class TeamMigration::Leicestershire < TeamMigration::Base
  def perform
    set_team_workgroup(team, "leicestershiresais")
    add_team_programmes(team, "flu")

    team
      .schools
      .includes(:location_programme_year_groups)
      .find_each do |location|
        add_school_year_groups(location, team.programmes, sen: false)
      end

    SEN_SCHOOL_URNS.each do |urn|
      location = Location.school.find_by!(urn:)
      attach_school_to_team(location, team)
      add_school_year_groups(location, team.programmes, sen: true)
    end
  end

  private

  SEN_SCHOOL_URNS = %w[
    120330
    120348
    120352
    120363
    128078
    130371
    131018
    131099
    134438
    134640
    134938
    135217
    135530
    139559
    139734
    141127
    142635
    142659
    142779
    142939
    144619
    146360
    147607
    147963
    148027
    148245
    148424
    149200
    150440
    151121
  ].freeze

  def ods_code = "RT5"

  def team
    @team ||= Team.find_by!(organisation:)
  end
end
