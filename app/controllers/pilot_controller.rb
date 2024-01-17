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

    if @cohort_list.valid?
      @cohort_list.generate_cohort!

      if @cohort_list.errors.any?
        render :errors, status: :unprocessable_entity, layout: "application"
      else
        redirect_to action: :success
      end
    else
      render :cohort, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def cohort_list_params
    params.fetch(:cohort_list, {}).permit(:csv)
  end
end
