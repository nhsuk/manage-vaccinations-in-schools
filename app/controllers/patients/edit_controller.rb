# frozen_string_literal: true

class Patients::EditController < ApplicationController
  before_action :set_patient

  def edit_nhs_number
    render :nhs_number
  end

  def update_nhs_number
    if @patient.update(nhs_number_params)
      redirect_to edit_patient_path(@patient)
    else
      render :nhs_number, status: :unprocessable_entity
    end
  end

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:id])
  end

  def nhs_number_params
    params.require(:patient).permit(:nhs_number)
  end
end
