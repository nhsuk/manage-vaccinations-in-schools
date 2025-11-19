# frozen_string_literal: true

module AppNavigationConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_cached_counts
    before_action :set_app_navigation
    after_action :set_navigation_counts_cookie
  end

  def set_cached_counts
    @cached_counts = TeamCachedCounts.new(current_team)
  end

  def set_app_navigation
    # To handle the start, login and select team pages.
    if current_team.blank?
      @app_navigation_items = []
      return
    end

    @app_navigation_items =
      (
        if current_team.has_poc_access?
          [
            {
              title: t("programmes.index.title"),
              path: programmes_path,
              count: nil
            },
            {
              title: t("sessions.index.title"),
              path: sessions_path,
              count: nil
            },
            {
              title: t("patients.index.title"),
              path: patients_path,
              count: nil
            },
            {
              title: t("consent_forms.index.title_short"),
              path: consent_forms_path,
              count: @cached_counts.unmatched_consent_responses
            },
            {
              title: t("school_moves.index.title"),
              path: school_moves_path,
              count: @cached_counts.school_moves
            },
            {
              title: t("vaccines.index.title"),
              path: vaccines_path,
              count: nil
            }
          ]
        else
          []
        end
      )

    @app_navigation_items += [
      {
        title: t("imports.index.title_short"),
        path: imports_path,
        count: @cached_counts.import_issues
      },
      { title: t("teams.show.title"), path: team_path, count: nil }
    ]
  end

  # Used by Reporting to display counts in their header
  def set_navigation_counts_cookie
    return unless current_user

    unmatched_consent_responses =
      @cached_counts.unmatched_consent_responses || 0
    school_moves = @cached_counts.school_moves || 0
    imports = @cached_counts.import_issues || 0

    cookies[:mavis_navigation_counts] = {
      unmatched_consent_responses:,
      school_moves:,
      imports:
    }.to_json
  end
end
