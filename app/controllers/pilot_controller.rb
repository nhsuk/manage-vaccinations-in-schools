class PilotController < ApplicationController
  layout "two_thirds"

  def manage
  end

  def cohort
    @cohort_list = CohortList.new
  end

  def create
    @cohort_list = CohortList.new(cohort_list_params)

    @cohort_list.load_data!
    if @cohort_list.invalid?
      return render :cohort, status: :unprocessable_entity
    end

    @cohort_list.parse_rows!
    if @cohort_list.errors.any?
      return render :errors, status: :unprocessable_entity, layout: "application"
    end

    redirect_to action: :success
  end

  def success
  end

  private

  def cohort_list_params
    params.fetch(:cohort_list, {}).permit(:csv)
  end
end
