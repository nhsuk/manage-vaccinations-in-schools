# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :set_programme

  def index
    @immunisation_imports =
      @programme
        .immunisation_imports
        .recorded
        .includes(:uploaded_by)
        .order(:created_at)
        .strict_loading

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

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end
end
