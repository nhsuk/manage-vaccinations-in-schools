# frozen_string_literal: true

class Patients::EditController < Patients::BaseController
  before_action :set_patient_merge_form, except: :edit_nhs_number
  before_action :set_existing_patient, except: :edit_nhs_number

  def edit_nhs_number
    render :nhs_number
  end

  def update_nhs_number
    @patient.nhs_number = nhs_number.presence

    redirect_to edit_patient_path(@patient) and return unless @patient.changed?

    render :nhs_number_merge and return if @existing_patient

    @patient.invalidated_at = nil

    if @patient.save
      PatientUpdateFromPDSJob.perform_later(@patient)

      redirect_to edit_patient_path(@patient)
    else
      render :nhs_number, status: :unprocessable_content
    end
  end

  def update_nhs_number_merge
    if @form.save
      redirect_to edit_patient_path(@existing_patient)
    else
      render :nhs_number_merge, status: :unprocessable_entity
    end
  end

  private

  def set_patient_merge_form
    @form = PatientMergeForm.new(current_user:, patient: @patient, nhs_number:)
  end

  def set_existing_patient
    @existing_patient = @form.existing_patient
  end

  def nhs_number
    params.dig(:patient, :nhs_number) ||
      params.dig(:patient_merge_form, :nhs_number)
  end
end
