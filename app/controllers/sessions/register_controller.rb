# frozen_string_literal: true

require "pagy/extras/array"

class Sessions::RegisterController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_session
  before_action :set_search_form, only: :show
  before_action :set_patient_session, only: :create

  layout "full"

  def show
    @statuses = PatientSession::RegisterOutcome::STATUSES

    scope =
      @session.patient_sessions.preload_for_status.in_programmes(
        @session.programmes
      )

    patient_sessions =
      @form.apply(scope) do |filtered_scope|
        filtered_scope.select(&:ready_for_vaccinator?)
      end

    if patient_sessions.is_a?(Array)
      @pagy, @patient_sessions = pagy_array(patient_sessions)
    else
      @pagy, @patient_sessions = pagy(patient_sessions)
    end
  end

  def create
    session_attendance = authorize @patient_session.register.latest
    session_attendance.update!(attending: params[:status] == "present")

    name = @patient_session.patient.full_name

    flash[:info] = if session_attendance.attending?
      t("attendance_flash.present", name:)
    else
      t("attendance_flash.absent", name:)
    end

    redirect_to session_register_path(
                  @session,
                  **params.permit(search_form: {})
                )
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:programmes, :session_dates).find_by!(
        slug: params[:session_slug]
      )
  end

  def set_patient_session
    @patient_session =
      @session.patient_sessions.preload_for_status.find_by!(
        patient_id: params[:patient_id]
      )
  end
end
