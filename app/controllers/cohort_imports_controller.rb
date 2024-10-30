# frozen_string_literal: true

class CohortImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_programme
  before_action :set_cohort_import, only: %i[show update]

  def new
    @cohort_import = CohortImport.new
  end

  def create
    @cohort_import =
      CohortImport.new(
        programme: @programme,
        organisation: current_user.selected_organisation,
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
    @cohort_import.load_serialized_errors! if @cohort_import.rows_are_invalid?

    @pagy, @patients = pagy(@cohort_import.patients.includes(:school))

    @duplicates = @cohort_import.patients.with_pending_changes.distinct

    render template: "imports/show",
           layout: "full",
           locals: {
             import: @cohort_import
           }
  end

  def update
    @cohort_import.record!

    redirect_to programme_cohort_import_path(@programme, @cohort_import)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_cohort_import
    @cohort_import = policy_scope(CohortImport).find(params[:id])
  end

  def cohort_import_params
    params.fetch(:cohort_import, {}).permit(:csv)
  end
end
