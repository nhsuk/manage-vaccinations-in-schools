# frozen_string_literal: true

class StatusGenerator::Registration
  def initialize(patient_session:, session_attendance:, vaccination_records:)
    @patient_session = patient_session
    @session_attendance = session_attendance
    @vaccination_records = vaccination_records
  end

  def status
    if status_should_be_completed?
      :completed
    elsif status_should_be_attending?
      :attending
    elsif status_should_be_not_attending?
      :not_attending
    else
      :unknown
    end
  end

  private

  attr_reader :patient_session, :session_attendance, :vaccination_records

  def academic_year = patient_session.session.academic_year

  def status_should_be_completed?
    patient_session.programmes.all? do |programme|
      vaccination_records.any? do
        it.programme_id == programme.id &&
          it.session_id == patient_session.session_id
      end
    end
  end

  def status_should_be_attending?
    session_attendance&.attending
  end

  def status_should_be_not_attending?
    session_attendance&.attending == false
  end
end
