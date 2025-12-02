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
            description: [
              "upload vaccination records",
              "check the status of your uploads",
              "view previous uploads"
            ]
          },
          {
            title: "Vaccination records",
            description: [
              "find vaccination records",
              "edit vaccination records"
            ]
          },
          {
            title: "Reports",
            description: ["view reports on vaccination records"]
          }
        ]
      else
        [
          {
            title: I18n.t("programmes.index.title"),
            path: programmes_path,
            description: [
              "import child records",
              "organise vaccination sessions",
              "report vaccinations"
            ]
          },
          {
            title: I18n.t("sessions.index.title"),
            path: sessions_path,
            description: [
              "review consent responses",
              "triage health records",
              "record vaccinations",
              "review session outcomes"
            ]
          },
          {
            title: I18n.t("patients.index.title"),
            path: patients_path,
            description: ["find child records", "view child vaccinations"]
          }
        ]
      end
  end

  def set_secondary_items
    @secondary_items = []

    unless current_team.has_upload_access_only?
      @secondary_items << {
        title: I18n.t("consent_forms.index.title"),
        path: consent_forms_path,
        description:
          "Review incoming consent responses that can’t be automatically matched"
      }

      @secondary_items << {
        title: I18n.t("school_moves.index.title"),
        path: school_moves_path,
        description: "Review children who have moved schools"
      }

      @secondary_items << {
        title: I18n.t("imports.index.title"),
        path: imports_path,
        description:
          "Import child, cohort and vaccination records and see important notices"
      }

      @secondary_items << {
        title: I18n.t("vaccines.index.title"),
        path: vaccines_path,
        description: "Add and edit vaccine batches"
      }
    end

    @secondary_items << {
      title: I18n.t("teams.show.title"),
      path: team_path,
      description: "Manage your team’s settings"
    }

    @secondary_items << {
      title: I18n.t("service.guide.title"),
      path: @service_guide_url,
      description: "How to use this service"
    }
  end
end
