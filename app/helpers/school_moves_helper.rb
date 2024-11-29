# frozen_string_literal: true

module SchoolMovesHelper
  def school_move_source(school_move)
    organisation = school_move.school&.organisation || school_move.organisation

    if organisation == current_user.selected_organisation
      {
        parental_consent_form: "Consent response updated",
        class_list_import: "Class list updated",
        cohort_import: "Cohort record updated"
      }.fetch(school_move.source.to_sym)
    else
      "Another SAIS team updated"
    end
  end
end
