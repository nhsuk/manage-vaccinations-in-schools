# frozen_string_literal: true

class Users::TeamsController < ApplicationController
  skip_before_action :store_user_location!
  skip_before_action :ensure_team_is_selected
  skip_after_action :verify_policy_scoped

  layout "two_thirds"

  def new
    @form = SelectTeamForm.new(cis2_info:, current_user:)

    if @form.teams.count == 1
      @form.team_id = @form.teams.first.id

      redirect_to return_to_path if @form.save
    end
  end

  def create
    @form =
      SelectTeamForm.new(
        cis2_info:,
        current_user:,
        team_id: params.dig(:select_team_form, :team_id)
      )

    if @form.save
      redirect_to return_to_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def return_to_path
    after_sign_in_path_for(current_user) || session[:user_return_to] ||
      dashboard_path
  end
end
