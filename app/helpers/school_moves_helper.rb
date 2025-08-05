# frozen_string_literal: true

module SchoolMovesHelper
  def school_move_source(school_move)
    team = school_move.school&.team || school_move.team

    source =
      if team == current_team
        school_move.human_enum_name(:source)
      else
        "Another SAIS team"
      end

    "#{source} updated"
  end
end
