# frozen_string_literal: true

class Users::TeamsController < ApplicationController
  skip_before_action :set_selected_team
  skip_after_action :verify_policy_scoped

  before_action :redirect_to_dashboard_if_cis2_is_enabled

  layout "two_thirds"

  def new
    @teams = current_user.teams
  end

  def create
    team = current_user.teams.find(params[:team_id])

    if team.present?
      session["cis2_info"] = {
        "selected_org" => {
          "name" => team.name,
          "code" => team.ods_code
        },
        "selected_role" => {
          "code" => valid_cis2_roles.first,
          "workgroups" => ["schoolagedimmunisations"]
        }
      }

      redirect_to dashboard_path
    else
      @teams = current_user.teams
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_to_dashboard_if_cis2_is_enabled
    redirect_to dashboard_path if Settings.cis2.enabled
  end
end
