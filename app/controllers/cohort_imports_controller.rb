# frozen_string_literal: true

class CohortImportsController < ApplicationController
  before_action :set_programme
  before_action :set_cohort_import, only: %i[show]
  before_action :set_patients, only: %i[show]

  def new
    @cohort_import = CohortImport.new
  end

  def create
    @cohort_import =
      CohortImport.new(uploaded_by: current_user, **cohort_import_params)

    @cohort_import.load_data!
    if @cohort_import.invalid?
      render :new, status: :unprocessable_entity
      return
    end

    @cohort_import.parse_rows!
    if @cohort_import.invalid?
      render :errors, status: :unprocessable_entity
      return
    end

    @cohort_import.process!

    if @cohort_import.processed_only_exact_duplicates?
      render :duplicates
      return
    end

    @cohort_import.record!

    redirect_to programme_cohort_import_path(@programme, @cohort_import)
  end

  def show
  end

  private

  def set_programme
    @programme = policy_scope(Programme).active.find(params[:programme_id])
  end

  def set_cohort_import
    # TODO: @programme.cohort_imports.find
    @cohort_import = CohortImport.find(params[:id])
  end

  def set_patients
    @patients = @cohort_import.patients
  end

  def cohort_import_params
    params.fetch(:cohort_import, {}).permit(:csv)
  end
end
