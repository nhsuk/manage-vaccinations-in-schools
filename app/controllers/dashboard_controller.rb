# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped

  before_action :set_primary_items, :set_secondary_items

  layout "full"

  def index
    @notices_count =
      (policy_scope(ImportantNotice).count if policy(ImportantNotice).index?)
  end

  private

  def set_primary_items
    @primary_items =
      if current_team.has_upload_access_only?
        [
          {
            title: I18n.t("imports.index.title"),
            path: imports_path,
            description: I18n.t("imports.index.description")
          },
          {
            title: I18n.t("vaccination_records.index.title"),
            description: I18n.t("vaccination_records.index.description")
          },
          {
            title: I18n.t("reports.index.title"),
            description: I18n.t("reports.index.description")
          }
        ]
      else
        [
          if Flipper.enabled?(:schools_and_sessions)
            {
              title: I18n.t("schools.index.title"),
              path: schools_path,
              description: I18n.t("schools.index.description")
            }
          else
            {
              title: I18n.t("programmes.index.title"),
              path: programmes_path,
              description: I18n.t("programmes.index.description")
            }
          end,
          {
            title: I18n.t("patients.index.title"),
            path: patients_path,
            description: I18n.t("patients.index.description")
          },
          {
            title: I18n.t("sessions.index.title"),
            path: sessions_path,
            description: I18n.t("sessions.index.description")
          },
          {
            title: I18n.t("vaccines.index.title"),
            path: vaccines_path,
            description: I18n.t("vaccines.index.description")
          }
        ]
      end
  end

  def set_secondary_items
    @secondary_items = []

    unless current_team.has_upload_access_only?
      @secondary_items << {
        title: I18n.t("school_moves.index.title"),
        path: school_moves_path,
        description: I18n.t("school_moves.index.description")
      }

      @secondary_items << {
        title: I18n.t("consent_forms.index.title"),
        path: consent_forms_path,
        description: I18n.t("consent_forms.index.description")
      }

      @secondary_items << {
        title: I18n.t("imports.index.title"),
        path: imports_path,
        description: I18n.t("imports.index.description")
      }

      if Flipper.enabled?(:schools_and_sessions)
        @secondary_items << {
          title: I18n.t("programmes.index.title"),
          path: programmes_path,
          description: I18n.t("programmes.index.description")
        }
      end
    end

    @secondary_items << {
      title: I18n.t("teams.show.title"),
      path: team_path,
      description: I18n.t("teams.show.description")
    }

    @secondary_items << {
      title: I18n.t("service.guide.title"),
      path: @service_guide_url,
      description: I18n.t("service.guide.description")
    }
  end
end
