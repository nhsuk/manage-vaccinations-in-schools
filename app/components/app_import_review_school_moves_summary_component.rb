# frozen_string_literal: true

class AppImportReviewSchoolMovesSummaryComponent < ViewComponent::Base
  def initialize(changesets:)
    @changesets = changesets
    @destination_schools = {}
  end

  private

  def destination_school_name(changeset)
    school = destination_school(changeset)
    home_educated = changeset.review_data.dig("school_move", "home_educated")

    if school.present?
      school.name
    elsif home_educated
      "Home educated"
    else
      "Unknown school"
    end
  end

  def destination_school(changeset)
    @destination_schools[changeset.id] ||= begin
      destination_school_id =
        changeset.review_data.dig("school_move", "school_id")
      Location.find(destination_school_id) if destination_school_id.present?
    end
  end

  def school_move_across_teams?(changeset)
    patient = changeset.patient
    dest_school = destination_school(changeset)

    dest_school && patient.school &&
      (dest_school.teams & patient.school.teams).empty?
  end
end
