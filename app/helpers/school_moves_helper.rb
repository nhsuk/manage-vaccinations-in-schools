# frozen_string_literal: true

module SchoolMovesHelper
  def school_move_source(school_move)
    teams = (school_move.school_teams + [school_move.team].compact)

    source =
      if teams.include?(current_team)
        school_move.human_enum_name(:source)
      else
        "Another SAIS team"
      end

    "#{source} updated"
  end
end
