# frozen_string_literal: true

class SessionAttendancesController < ApplicationController
  before_action :set_patient_session
  before_action :set_session
  before_action :set_patient
  before_action :set_section_and_tab
  before_action :set_back_link
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
      flash[:info] = if @session_attendance.attending?
        "#{name} is attending today’s session. They are ready for the nurse."
      elsif @session_attendance.attending.nil?
        "#{name} is not registered yet."
      else
        "#{name} is absent from today’s session."
      end
      redirect_to(session_patient_path(id: @patient.id))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession)
        .includes(:patient, :vaccination_records)
        .eager_load(:session)
        .preload(:consents, :triages)
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

  def set_back_link
    @back_link = session_patient_path(id: @patient.id)
  end

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_session_attendance
    @session_attendance =
      @patient_session.session_attendances.find_or_initialize_by(
        session_date: @session_date
      )
  end

  def session_attendance_params
    params
      .require(:session_attendance)
      .tap { |p| p[:attending] = nil if p[:attending] == "not_registered" }
      .permit(:attending)
  end
end
