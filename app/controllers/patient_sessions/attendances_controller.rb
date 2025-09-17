# frozen_string_literal: true

class PatientSessions::AttendancesController < PatientSessions::BaseController
  before_action :set_session_date
  before_action :set_attendance_record

  def edit
  end

  def update
    @attendance_record.assign_attributes(attendance_record_params)

    if @attendance_record.attending.nil?
      @attendance_record.destroy!
    else
      @attendance_record.save!
    end => success

    StatusUpdater.call(patient: @patient)

    if success
      name = @patient.full_name

      flash[:info] = if @attendance_record.attending?
        t("attendance_flash.present", name:)
      elsif @attendance_record.attending.nil?
        t("attendance_flash.not_registered", name:)
      else
        t("attendance_flash.absent", name:)
      end

      programme = @session.programmes_for(patient: @patient).first
      redirect_to session_patient_programme_path(@session, @patient, programme)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_attendance_record
    attendance_record =
      @patient.attendance_records.find_or_initialize_by(
        location: @session.location,
        date: @session_date.value
      )

    attendance_record.session = @session

    @attendance_record = authorize attendance_record
  end

  def attendance_record_params
    params
      .expect(attendance_record: :attending)
      .tap { it[:attending] = nil if it[:attending] == "not_registered" }
  end
end
