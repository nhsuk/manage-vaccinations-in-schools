# frozen_string_literal: true

class Patients::EditController < ApplicationController
  before_action :set_patient

  def edit_nhs_number
    render :nhs_number
  end

  def update_nhs_number
    @patient.nhs_number = nhs_number
    redirect_to edit_patient_path(@patient) and return unless @patient.changed?

    @existing_patient = policy_scope(Patient).find_by(nhs_number:)

    if @existing_patient
      render :nhs_number_merge
    elsif @patient.save
      redirect_to edit_patient_path(@patient)
    else
      render :nhs_number, status: :unprocessable_entity
    end
  end

  def update_nhs_number_merge
    @existing_patient = policy_scope(Patient).find_by!(nhs_number:)

    PatientMerger.call(to_keep: @existing_patient, to_destroy: @patient)

    redirect_to edit_patient_path(@existing_patient)
  end

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:id])
  end

  def nhs_number
    params.dig(:patient, :nhs_number)
  end
end
