# frozen_string_literal: true

class TeamCachedCounts
  def initialize(team)
    @team = team
  end

  def import_issues
    return nil if current_user.nil?

    Rails
      .cache
      .fetch(import_issues_key) do
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
            .with_pending_changes_for_team(team:)
            .pluck(:id)

        (vaccination_records_with_issues + patients_with_issues).uniq.length
      end
  end

  def reset_import_issues!
    Rails.cache.delete(import_issues_key)
  end

  def school_moves
    return nil if current_user.nil?

    Rails
      .cache
      .fetch(school_moves_key) do
        SchoolMovePolicy::Scope.new(current_user, SchoolMove).resolve.count
      end
  end

  def reset_school_moves!
    Rails.cache.delete(school_moves_key)
  end

  def unmatched_consent_responses
    return nil if current_user.nil?

    Rails
      .cache
      .fetch(unmatched_consent_responses_key) do
        ConsentFormPolicy::Scope
          .new(current_user, ConsentForm)
          .resolve
          .unmatched
          .count
      end
  end

  def reset_unmatched_consent_responses!
    Rails.cache.delete(unmatched_consent_responses_key)
  end

  def reset_all!
    reset_import_issues!
    reset_school_moves!
    reset_unmatched_consent_responses!
  end

  private

  attr_reader :team

  def import_issues_key = cache_key("import-issues")

  def school_moves_key = cache_key("school-moves")

  def unmatched_consent_responses_key = cache_key("unmatched-consent-responses")

  def current_user
    # We can't use the policy_scope helper here as we're not in a controller.
    # Instead, we can mock what a `User` looks like from the perspective of a
    # controller to satisfy the policy scopes.
    @current_user ||=
      if team && (organisation = team.organisation)
        OpenStruct.new(selected_team: team, selected_organisation: organisation)
      end
  end

  def cache_key(type) = "cached-counts/#{type}/#{team.id}"
end
