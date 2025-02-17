# frozen_string_literal: true

class SessionAttendancesController < ApplicationController
  before_action :set_patient_session
  before_action :set_session
  before_action :set_patient
  before_action :set_section_and_tab
  before_action :set_session_date
  before_action :set_session_attendance

  layout "three_quarters"

  def edit
  end

  def update
    @session_attendance.assign_attributes(session_attendance_params)

    if @session_attendance.attending.nil?
      @session_attendance.destroy!
    else
      @session_attendance.save!
    end => success

    if success
      name = @patient.full_name

      programme = @patient_session.programmes.first # TODO: handle multiple programmes

      flash[:info] = if @session_attendance.attending?
        status = @patient_session.status(programme:)
        t("attendance_flash.#{status}", name:)
      elsif @session_attendance.attending.nil?
        t("attendance_flash.not_registered", name:)
      else
        t("attendance_flash.absent", name:)
      end

      redirect_to session_patient_programme_path(
                    patient_id: @patient.id,
                    programme_type: programme.type
                  )
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession)
        .eager_load(:patient, :session)
        .preload(:programmes, patient: %i[consents triages vaccination_records])
        .find_by!(
          session: {
            slug: params.fetch(:session_slug)
          },
          patient_id: params.fetch(:id, params[:patient_id])
        )
  end

  def set_session
    @session = @patient_session.session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_session_attendance
    @session_attendance =
      authorize @patient_session
                  .session_attendances
                  .includes(:patient, :session_date)
                  .find_or_initialize_by(session_date: @session_date)
  end

  def session_attendance_params
    params
      .expect(session_attendance: :attending)
      .tap { |p| p[:attending] = nil if p[:attending] == "not_registered" }
  end
end
