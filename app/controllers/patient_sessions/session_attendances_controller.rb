# frozen_string_literal: true

class PatientSessions::SessionAttendancesController < PatientSessions::BaseController
  before_action :set_session_date
  before_action :set_session_attendance

  def edit
  end

  def update
    @session_attendance.assign_attributes(session_attendance_params)

    if @session_attendance.attending.nil?
      @session_attendance.destroy!
    else
      @session_attendance.save!
    end => success

    StatusUpdater.call(patient: @patient)

    if success
      name = @patient.full_name

      flash[:info] = if @session_attendance.attending?
        t("attendance_flash.present", name:)
      elsif @session_attendance.attending.nil?
        t("attendance_flash.not_registered", name:)
      else
        t("attendance_flash.absent", name:)
      end

      redirect_to session_patient_programme_path(
                    @session,
                    @patient,
                    @patient_session.programmes.first
                  )
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

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
