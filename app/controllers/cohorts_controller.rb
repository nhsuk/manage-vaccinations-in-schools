# frozen_string_literal: true

class CohortsController < ApplicationController
  include Pagy::Backend

  before_action :set_programme

  layout "full"

  def index
    year_groups = @programme.year_groups

    cohorts =
      policy_scope(Cohort)
        .select("cohorts.*", "COUNT(patients.id) AS patient_count")
        .for_year_groups(year_groups)
        .left_outer_joins(:patients)
        .group("cohorts.id")
        .index_by(&:year_group)

    year_groups.each do |year_group|
      cohorts[year_group] ||= OpenStruct.new(year_group:, patient_count: 0)
    end

    @cohorts = cohorts.sort.map { _2 }
  end

  def show
    @cohort = policy_scope(Cohort).find(params[:id])
    @pagy, @patients =
      pagy(@cohort.patients.not_deceased.includes(:school).order_by_name)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end
end
