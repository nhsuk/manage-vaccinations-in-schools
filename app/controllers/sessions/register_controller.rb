# frozen_string_literal: true

class Sessions::RegisterController < Sessions::BaseController
  include PatientSearchFormConcern

  before_action :set_patient_search_form, only: :show
  before_action :set_session_date, only: :create
  before_action :set_patient, only: :create

  layout "full"

  def show
    @statuses = Patient::RegistrationStatus.statuses.keys

    scope =
      @session.patients.includes_statuses.includes(
        :registration_statuses,
        notes: :created_by
      )

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
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

  def set_session_date
    @session_date = @session.session_dates.find_by!(value: Date.current)
  end

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end
end
