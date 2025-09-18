# frozen_string_literal: true

class TeamCachedCounts
  def initialize(team)
    @team = team
  end

  def import_issues
    return nil if current_user.nil?

    vaccination_records_with_issues =
      VaccinationRecordPolicy::Scope
        .new(current_user, VaccinationRecord)
        .resolve
        .with_pending_changes
        .pluck(:patient_id)

    patients_with_issues =
      PatientPolicy::Scope
        .new(current_user, Patient)
        .resolve
        .with_pending_changes
        .pluck(:id)

    (vaccination_records_with_issues + patients_with_issues).uniq.length
  end

  def school_moves
    return nil if current_user.nil?

    SchoolMovePolicy::Scope.new(current_user, SchoolMove).resolve.count
  end

  def unmatched_consent_responses
    return nil if current_user.nil?

    ConsentFormPolicy::Scope
      .new(current_user, ConsentForm)
      .resolve
      .unmatched
      .recorded
      .not_archived
      .count
  end

  private

  attr_reader :team

  def current_user
    # We can't use the policy_scope helper here as we're not in a controller.
    # Instead, we can mock what a `User` looks like from the perspective of a
    # controller to satisfy the policy scopes.
    @current_user ||=
      if team && (organisation = team.organisation)
        OpenStruct.new(selected_team: team, selected_organisation: organisation)
      end
  end
end
