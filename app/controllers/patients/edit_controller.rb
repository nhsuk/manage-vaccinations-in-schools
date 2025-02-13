# frozen_string_literal: true

class Patients::EditController < ApplicationController
  before_action :set_patient

  def edit_nhs_number
    render :nhs_number
  end

  def update_nhs_number
    @patient.nhs_number = nhs_number.presence

    redirect_to edit_patient_path(@patient) and return unless @patient.changed?

    render :nhs_number_merge and return if existing_patient

    @patient.invalidated_at = nil

    if @patient.save
      PatientUpdateFromPDSJob.perform_later(@patient)

      redirect_to edit_patient_path(@patient)
    else
      render :nhs_number, status: :unprocessable_entity
    end
  end

  def update_nhs_number_merge
    PatientMerger.call(to_keep: existing_patient, to_destroy: @patient)

    redirect_to edit_patient_path(existing_patient)
  end

  private

  def set_patient
    @patient =
      policy_scope(Patient).includes(parent_relationships: :parent).find(
        params[:id]
      )
  end

  def existing_patient
    @existing_patient ||=
      if nhs_number.present?
        policy_scope(Patient)
          .or(Patient.where(organisation: nil))
          .includes(parent_relationships: :parent)
          .find_by(nhs_number:)
      end
  end

  def nhs_number
    params.dig(:patient, :nhs_number)
  end
end
