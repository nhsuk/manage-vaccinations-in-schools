# frozen_string_literal: true

class RegisterAttendancesController < ApplicationController
  include PatientSortingConcern

  before_action :set_session, only: %i[index create]
  before_action :set_session_date
  before_action :set_patient_sessions, only: :index
  before_action :set_patient, only: :create
  before_action :set_patient_session, only: :create

  layout "full"

  def index
    sort_and_filter_patients!(@patient_sessions)
  end

  def create
    session_attendance =
      authorize @patient_session.session_attendances.find_or_initialize_by(
                  session_date: @session_date
                )

    session_attendance.update!(attending: params[:state] == "attending")

    name = @patient.full_name

    flash[:info] = if session_attendance.attending?
      t("attendance_flash.present", name:)
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
    ps =
      @session.patient_sessions.preload_for_status.includes(
        :patient,
        session: :session_dates,
        session_attendances: :session_date
      )

    @patient_sessions =
      ps
        .where
        .missing(:session_attendances)
        .or(ps.where.not(session_attendances: { session_date: @session_date }))
        .to_a
  end

  def set_patient
    @patient = @session.patients.find_by(id: params[:patient_id])
  end

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_patient_session
    @patient_session =
      @patient.patient_sessions.preload_for_status.find_by!(session: @session)
  end
end
