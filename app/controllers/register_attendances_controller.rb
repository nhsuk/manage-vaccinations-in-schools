# frozen_string_literal: true

class RegisterAttendancesController < ApplicationController
  include PatientSortingConcern

  before_action :set_session, only: %i[index create]
  before_action :set_patient_sessions, only: %i[index]
  before_action :set_patient, only: %i[create]
  before_action :set_session_date, only: %i[create]
  before_action :set_patient_session, only: %i[create]

  layout "full"

  def index
    sort_and_filter_patients!(@patient_sessions)
  end

  def create
    session_attendance =
      @patient_session.session_attendances.create!(
        session_date: @session_date,
        attending: params[:state] == "attending"
      )

    name = @patient.full_name
    flash[:info] = if session_attendance.attending?
      t("attendance_flash.#{@patient_session.status}", name:)
    else
      t("attendance_flash.absent", name:)
    end
    redirect_to session_attendances_path(@session)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_patient_sessions
    @patient_sessions =
      @session.patient_sessions.select { _1.current_attendance.nil? }
  end

  def set_patient
    @patient = @session.patients.find_by(id: params[:patient_id])
  end

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end
end
