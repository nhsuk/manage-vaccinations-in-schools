# frozen_string_literal: true

class Patients::ArchiveController < Patients::BaseController
  before_action :set_archive_reason

  def new
    @form = PatientArchiveForm.new
  end

  def create
    @form =
      PatientArchiveForm.new(
        archive_reason: @archive_reason,
        current_user:,
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

  def set_archive_reason
    @archive_reason = ArchiveReason.find_or_create_by(team:, patient: @patient)
  end

  def team = current_user.selected_team

  def patient_archive_form_params
    params.expect(patient_archive_form: %i[nhs_number type other_details])
  end
end
