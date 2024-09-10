# frozen_string_literal: true

class CohortImportsController < ApplicationController
  before_action :set_programme

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

    @cohort_import.record!

    redirect_to action: :success
  end

  def success
  end

  private

  def set_programme
    @programme = policy_scope(Programme).active.find(params[:programme_id])
  end

  def cohort_import_params
    params.fetch(:cohort_import, {}).permit(:csv)
  end
end
