# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :set_team, :set_programme

  def index
    render layout: "full"
  end

  def new
  end

  def create
    redirect_to(
      if params[:type] == "vaccinations"
        new_programme_immunisation_import_path(@programme)
      elsif params[:type] == "children"
        new_programme_cohort_import_path(@programme)
      else
        new_programme_import_path(@programme)
      end
    )
  end

  private

  def set_team
    @team = current_user.team
  end

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
