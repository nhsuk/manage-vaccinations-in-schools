# frozen_string_literal: true

module SchoolMovesHelper
  def school_move_source(school_move)
    organisation = school_move.school&.organisation || school_move.organisation

    source =
      if organisation == current_organisation
        school_move.human_enum_name(:source)
      else
        "Another SAIS organisation"
      end

    "#{source} updated"
  end
end
