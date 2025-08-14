# frozen_string_literal: true

class TeamMigration::Coventry < TeamMigration::Base
  def perform
    set_team_workgroup(team, "coventrywarwickshiresais")
    add_team_programmes(team, "flu")

    school_rows.each do |row|
      urn = row.fetch("URN")
      sen = row.fetch("SEN") == "SEN"
      subteam = subteams.fetch(row.fetch("Subteam"))

      process_row(urn, sen, subteam)
    end

    detach_school(urn: URN_TO_REMOVE)
  end

  private

  URN_TO_REMOVE = "131574"

  def ods_code = "RYG"

  def school_rows
    CSV.foreach(__FILE__.gsub(".rb", ".csv"), headers: true)
  end

  def process_row(urn, sen, subteam)
    location = Location.school.find_by!(urn:)
    attach_school_to_subteam(location, subteam)
    add_school_year_groups(location, team.programmes, sen:)
  end

  def team
    @team ||= Team.find_by!(organisation:)
  end

  SUBTEAMS = {
    "COV" => "Coventry School-Aged Immunisation Service",
    "N WARKS" => "North Warwickshire School-Aged Immunisation Service",
    "S WARKS" => "South Warwickshire School-Aged Immunisation Service"
  }.freeze

  def subteams
    @subteams ||= SUBTEAMS.transform_values { team.subteams.find_by!(name: it) }
  end
end
