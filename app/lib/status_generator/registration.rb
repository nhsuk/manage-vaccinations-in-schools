# frozen_string_literal: true

class StatusGenerator::Registration
  def initialize(patient:, session:, attendance_record:, vaccination_records:)
    @patient = patient
    @session = session
    @attendance_record = attendance_record
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

  attr_reader :patient, :session, :attendance_record, :vaccination_records

  def status_should_be_completed?
    session
      .programmes_for(patient:)
      .all? do |programme|
        vaccination_records.any? do
          it.programme_type == programme.type && it.session_id == session.id
        end
      end
  end

  def status_should_be_attending?
    attendance_record&.attending
  end

  def status_should_be_not_attending?
    attendance_record&.attending == false
  end
end
