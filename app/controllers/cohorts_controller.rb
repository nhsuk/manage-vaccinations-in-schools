# frozen_string_literal: true

class CohortsController < ApplicationController
  before_action :set_programme

  layout "full"

  def index
    @cohorts =
      policy_scope(Cohort)
        .for_year_groups(@programme.year_groups)
        .order(:reception_starting_year)
        .includes(:recorded_patients)
  end

  def show
    @cohort = policy_scope(Cohort).find(params[:id])
    @patients = @cohort.patients.recorded
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end
end
