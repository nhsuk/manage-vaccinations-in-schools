# frozen_string_literal: true

class PatientSession::Register
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [UNKNOWN = :unknown, PRESENT = :present, ABSENT = :absent].freeze

  def status
    @status ||=
      if latest&.attending
        PRESENT
      elsif latest&.attending == false
        ABSENT
      else
        UNKNOWN
      end
  end

  def latest
    @latest ||=
      if session_date
        session_attendances.find { it.session_date_id == session_date.id } ||
          session_attendances.new(session_date:)
      end
  end

  private

  attr_reader :patient_session

  delegate :session, :session_attendances, to: :patient_session

  def session_date
    @session_date ||= session.session_dates.find(&:today?)
  end
end
