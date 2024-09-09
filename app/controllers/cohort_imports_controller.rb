# frozen_string_literal: true

class CohortImportsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: %i[new create success]

  before_action :set_team, only: %i[new create]
  before_action :set_programme, only: %i[new create]

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

  def cohort_import_params
    params.fetch(:cohort_import, {}).permit(:csv)
  end

  def set_team
    @team = current_user.team
  end

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end
end