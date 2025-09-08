# frozen_string_literal: true

class Sessions::RegisterController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form, only: :show
  before_action :set_session_date, only: :create
  before_action :set_patient, only: :create

  layout "full"

  def show
    @statuses = Patient::RegistrationStatus.statuses.keys

    scope =
      @session.patient_locations.includes_programmes.includes(
        patient: [
          :consent_statuses,
          :registration_statuses,
          :triage_statuses,
          :vaccination_statuses,
          { notes: :created_by }
        ]
      )

    patient_locations = @form.apply(scope)
    @pagy, @patient_locations = pagy(patient_locations)
  end

  def create
    attendance_record =
      @patient.attendance_records.find_or_initialize_by(
        location: @session.location,
        date: @session_date.value
      )

    attendance_record.session = @session

    authorize attendance_record

    ActiveRecord::Base.transaction do
      attendance_record.update!(attending: params[:status] == "present")
      StatusUpdater.call(patient: @patient)
    end

    name = @patient.full_name

    flash[:info] = if attendance_record.attending?
      t("attendance_flash.present", name:)
    else
      t("attendance_flash.absent", name:)
    end

    redirect_to session_register_path(@session)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end
end
