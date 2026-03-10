# frozen_string_literal: true

class Patients::ProgrammesController < Patients::BaseController
  before_action :set_programme
  before_action :set_academic_year
  before_action :set_can_invite_to_clinic

  skip_after_action :verify_policy_scoped

  layout "full"

  def show
    authorize @patient
  end

  def invite_to_clinic
    authorize @patient

    ActiveRecord::Base.transaction do
      PatientLocation.find_or_create_by!(
        patient: @patient,
        location: current_team.generic_clinic,
        academic_year: @academic_year
      )

      PatientTeamUpdater.call(patient: @patient.id, team: current_team)
    end

    @patient.notifier.send_clinic_invitation(
      [@programme],
      team: current_team,
      academic_year: @academic_year,
      sent_by: current_user
    )

    redirect_to patient_programme_path(@patient, @programme),
                flash: {
                  success: "#{@patient.full_name} invited to the clinic"
                }
  end

  private

  def set_programme
    programme_type = params[:programme_type] || params[:type]
    return if programme_type.blank?

    @programme = Programme.find(programme_type, patient: @patient)

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_academic_year
    @academic_year = AcademicYear.pending
  end

  def set_can_invite_to_clinic
    @can_invite_to_clinic =
      @patient.notifier.can_send_clinic_invitation?(
        [@programme],
        team: current_team,
        academic_year: @academic_year,
        include_already_invited_programmes: false
      )
  end
end
