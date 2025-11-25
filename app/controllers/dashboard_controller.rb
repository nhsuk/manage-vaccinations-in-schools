# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  helper_method :dashboard_cards_partial, :team_has_upload_access_only?

  layout "full"

  def index
    @notices_count =
      (policy_scope(ImportantNotice).count if policy(ImportantNotice).index?)
  end

  def team_has_upload_access_only?
    current_team.has_upload_access_only?
  end

  def dashboard_cards_partial
    if team_has_upload_access_only?
      "dashboard_cards_upload_only"
    else
      "dashboard_cards_default"
    end
  end
end
