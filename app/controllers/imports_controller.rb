# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :set_team, :set_programme

  def index
    authorize :import

    render layout: "full"
  end

  def new
    authorize :import
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

    authorize :import
  end

  private

  def set_team
    @team = current_user.team
  end

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end
end
