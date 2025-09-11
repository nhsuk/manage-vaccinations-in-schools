# frozen_string_literal: true

class Patients::ArchiveController < Patients::BaseController
  def new
    @form = PatientArchiveForm.new
  end

  def create
    @form =
      PatientArchiveForm.new(
        current_user:,
        patient: @patient,
        **patient_archive_form_params
      )

    if @form.save
      flash[:success] = "This record has been archived"
      redirect_to patient_path(
                    @form.duplicate? ? @form.existing_patient : @patient
                  )
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def patient_archive_form_params
    params.expect(patient_archive_form: %i[nhs_number type other_details])
  end
end
