# frozen_string_literal: true

module NavigationConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_cached_counts
    before_action :set_navigation_items
    after_action :set_navigation_counts_cookie
  end

  def set_cached_counts
    @cached_counts = TeamCachedCounts.new(current_team)
  end

  def set_navigation_items
    @navigation_items = []

    if current_team&.has_poc_access?
      @navigation_items << if Flipper.enabled?(:schools_and_sessions)
        { title: t("schools.index.title"), path: schools_path }
      else
        { title: t("programmes.index.title"), path: programmes_path }
      end

      @navigation_items << {
        title: t("patients.index.title"),
        path: patients_path
      }

      @navigation_items << {
        title: t("sessions.index.title"),
        path: sessions_path
      }

      @navigation_items << {
        title: t("vaccines.index.title"),
        path: vaccines_path
      }

      @navigation_items << {
        title: t("consent_forms.index.title_short"),
        path: consent_forms_path,
        count: @cached_counts.unmatched_consent_responses
      }

      @navigation_items << {
        title: t("school_moves.index.title"),
        path: school_moves_path,
        count: @cached_counts.school_moves
      }
    end

    if current_team
      @navigation_items << {
        title: t("imports.index.title_short"),
        path: imports_path,
        count: @cached_counts.import_issues
      }
    end

    if current_team&.has_poc_access? && Flipper.enabled?(:schools_and_sessions)
      @navigation_items << {
        title: t("programmes.index.title"),
        path: programmes_path
      }
    end

    if current_team
      @navigation_items << {
        title:
          if Flipper.enabled?(:schools_and_sessions)
            I18n.t("teams.show.title_short")
          else
            I18n.t("teams.show.title")
          end,
        path: team_path
      }
    end
  end

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
