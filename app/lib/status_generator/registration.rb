# frozen_string_literal: true

class StatusGenerator::Registration
  def initialize(patient:, session:, session_attendance:, vaccination_records:)
    @patient = patient
    @session = session
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

  attr_reader :patient, :session, :session_attendance, :vaccination_records

  delegate :academic_year, to: :session

  def status_should_be_completed?
    session
      .programmes_for(patient:, academic_year:)
      .all? do |programme|
        vaccination_records.any? do
          it.programme_id == programme.id && it.session_id == session.id
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
