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
      CohortImport.new(
        programme: @programme,
        team: current_user.team,
        uploaded_by: current_user,
        **cohort_import_params
      )

    @cohort_import.load_data!
    if @cohort_import.invalid?
      render :new, status: :unprocessable_entity and return
    end

    @cohort_import.save!

    if @cohort_import.slow?
      ProcessImportJob.perform_later(@cohort_import)
      flash = { success: "Import processing started" }
    else
      ProcessImportJob.perform_now(@cohort_import)
      flash = { success: "Import completed" }
    end

    redirect_to programme_imports_path(@programme), flash:
  end

  def show
    render layout: "full"
  end

  def edit
    if @cohort_import.rows_are_invalid?
      @cohort_import.load_serialized_errors!
      render :errors and return
    end

    render layout: "full"
  end

  def update
    @cohort_import.record!

    redirect_to programme_cohort_import_path(@programme, @cohort_import)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end

  def set_cohort_import
    @cohort_import = policy_scope(CohortImport).find(params[:id])
  end

  def set_patients
    @patients = @cohort_import.patients
  end

  def cohort_import_params
    params.fetch(:cohort_import, {}).permit(:csv)
  end
end
