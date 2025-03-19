# frozen_string_literal: true

class PatientSession::RegisterOutcome
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    UNKNOWN = :unknown,
    ATTENDING = :attending,
    NOT_ATTENDING = :not_attending,
    COMPLETED = :completed
  ].freeze

  def unknown? = status == UNKNOWN

  def attending? = status == ATTENDING

  def not_attending? = status == NOT_ATTENDING

  def completed? = status == COMPLETED

  def status
    @status ||=
      if all_programmes_have_outcome?
        COMPLETED
      elsif latest&.attending
        ATTENDING
      elsif latest&.attending == false
        NOT_ATTENDING
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

  delegate :programmes,
           :session,
           :session_attendances,
           :session_outcome,
           to: :patient_session

  def session_date
    @session_date ||= session.session_dates.find(&:today?)
  end

  def all_programmes_have_outcome?
    programmes.all? do
      patient_session.vaccination_records.exists?(programme: it)
    end
  end
end
