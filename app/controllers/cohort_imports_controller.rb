# frozen_string_literal: true

class CohortImportsController < ApplicationController
  before_action :set_programme
  before_action :set_cohort_import, only: %i[show edit update]
  before_action :set_patients, only: %i[show edit]

  def new
    @cohort_import = CohortImport.new
  end

  def create
    @cohort_import =
      CohortImport.new(uploaded_by: current_user, **cohort_import_params)

    @cohort_import.load_data!
    if @cohort_import.invalid?
      render :new, status: :unprocessable_entity and return
    end

    @cohort_import.parse_rows!
    if @cohort_import.invalid?
      render :errors, status: :unprocessable_entity and return
    end

    @cohort_import.process!

    if @cohort_import.processed_only_exact_duplicates?
      render :duplicates and return
    end

    redirect_to edit_programme_cohort_import_path(@programme, @cohort_import)
  end

  def show
  end

  def edit
    render layout: "full"
  end

  def update
    @cohort_import.patients.each do |patient|
      cohort =
        Cohort
          .where(team: @programme.team)
          .where(
            "start_date <= ? AND end_date >= ?",
            patient.date_of_birth,
            patient.date_of_birth
          )
          .first
      patient.update!(cohort:)
    end

    @cohort_import.record!

    redirect_to programme_cohort_import_path(@programme, @cohort_import)
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
