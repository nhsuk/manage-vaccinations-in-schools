# frozen_string_literal: true

class CohortListsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: %i[new create success]

  before_action :set_team, only: %i[new create]

  def new
    @cohort_list = CohortList.new(team: @team)
  end

  def create
    @cohort_list = CohortList.new(cohort_list_params)

    @cohort_list.load_data!
    if @cohort_list.invalid?
      render :new, status: :unprocessable_entity
      return
    end

    @cohort_list.parse_rows!
    if @cohort_list.invalid?
      render :errors, status: :unprocessable_entity, layout: "application"
      return
    end

    @cohort_list.generate_patients!
    session[:last_cohort_upload_count] = @cohort_list.rows.count

    redirect_to action: :success
  end

  def success
    @count = session.delete(:last_cohort_upload_count)
  end

  private

  def cohort_list_params
    params.fetch(:cohort_list, {}).permit(:csv).merge(team: @team)
  end

  def set_team
    @team = current_user.team
  end
end
