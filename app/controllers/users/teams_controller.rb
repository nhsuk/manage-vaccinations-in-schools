# frozen_string_literal: true

class Users::TeamsController < ApplicationController
  skip_before_action :set_selected_team
  skip_after_action :verify_policy_scoped

  before_action :redirect_to_dashboard_if_cis2_is_enabled

  layout "two_thirds"

  def new
    @form = SelectTeamForm.new(cis2_info:, current_user:)
  end

  def create
    @form =
      SelectTeamForm.new(
        cis2_info:,
        current_user:,
        team_id: params.dig(:select_team_form, :team_id)
      )

    if @form.save
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def redirect_to_dashboard_if_cis2_is_enabled
    redirect_to dashboard_path if Settings.cis2.enabled
  end
end
