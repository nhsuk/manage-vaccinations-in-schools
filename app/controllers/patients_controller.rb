# frozen_string_literal: true

class PatientsController < ApplicationController
  include Pagy::Backend

  before_action :set_patient, except: :index

  def index
    scope = policy_scope(Patient).not_deceased

    if (@q = params[:q]).present?
      @q.strip!
      scope = scope.search_by_name(@q)
    end

    @pagy, @patients = pagy(scope.order_by_name)

    render layout: "full", status: request.post? ? :created : :ok
  end

  def show
  end

  def update
    cohort = @patient.cohort

    @patient.update!(patient_params)

    path =
      (
        if policy_scope(Patient).include?(@patient)
          patient_path(@patient)
        else
          patients_path
        end
      )

    redirect_to path,
                flash: {
                  success:
                    "#{@patient.full_name} removed from #{helpers.format_year_group(cohort.year_group)} cohort"
                }
  end

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(:cohort_id)
  end
end
