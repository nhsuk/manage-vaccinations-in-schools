# frozen_string_literal: true

class Sessions::RegisterController < ApplicationController
  include Pagy::Backend
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form, only: :show
  before_action :set_patient, only: :create
  before_action :set_patient_session, only: :create

  layout "full"

  def show
    @statuses = PatientSession::RegistrationStatus.statuses.keys

    scope =
      @session.patient_sessions.includes_programmes.includes(
        :latest_note,
        :registration_status,
        patient: %i[consent_statuses triage_statuses vaccination_statuses]
      )

    patient_sessions = @form.apply(scope)
    @pagy, @patient_sessions = pagy(patient_sessions)
  end

  def create
    session_attendance =
      ActiveRecord::Base.transaction do
        record = authorize @patient_session.todays_attendance
        record.update!(attending: params[:status] == "present")
        StatusUpdater.call(patient: @patient_session.patient)
        record
      end

    name = @patient_session.patient.full_name

    flash[:info] = if session_attendance.attending?
      t("attendance_flash.present", name:)
    else
      t("attendance_flash.absent", name:)
    end

    redirect_to session_register_path(
                  @session,
                  **params.permit(patient_search_form: {})
                )
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end

  def set_patient_session
    @patient_session =
      PatientSession.find_by!(patient: @patient, session: @session)
  end
end
