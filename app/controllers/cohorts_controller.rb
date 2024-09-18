# frozen_string_literal: true

class CohortsController < ApplicationController
  before_action :set_programme

  layout "full"

  def index
    cohorts =
      policy_scope(Cohort)
        .select("cohorts.*", "COUNT(patients.id) AS patient_count")
        .for_year_groups(@programme.year_groups)
        .left_outer_joins(:patients)
        .merge(Patient.recorded)
        .group("cohorts.id")
        .index_by(&:year_group)

    @programme.year_groups.each do |year_group|
      cohorts[year_group] ||= OpenStruct.new(year_group:, patient_count: 0)
    end

    @cohorts = cohorts.sort.map { _2 }
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
