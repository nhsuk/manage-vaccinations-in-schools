# frozen_string_literal: true

class TeamMigration::Leicestershire < TeamMigration::Base
  def perform
    set_team_workgroup(team, "leicestershiresais")
    add_team_programmes(team, "flu")

    school_rows.each do |row|
      urn = row.fetch("URN")
      sen = row.fetch("SEN") == "SEN"

      process_row(urn, sen)
    end
  end

  private

  def ods_code = "RT5"

  def team
    @team ||= Team.find_by!(organisation:)
  end

  def school_rows
    CSV.foreach(__FILE__.gsub(".rb", ".csv"), headers: true)
  end

  def process_row(urn, sen)
    location = Location.school.find_by!(urn:)
    attach_school_to_team(location, team)
    add_school_year_groups(location, team.programmes, sen:)
  end
end
