# frozen_string_literal: true

class RegisterOutcome
  def initialize(patient_sessions:)
    @patient_sessions = patient_sessions
  end

  STATUSES = [
    UNKNOWN = :unknown,
    ATTENDING = :attending,
    NOT_ATTENDING = :not_attending,
    COMPLETED = :completed
  ].freeze

  def unknown?(patient_session)
    status(patient_session) == UNKNOWN
  end

  def attending?(patient_session)
    status(patient_session) == ATTENDING
  end

  def not_attending?(patient_session)
    status(patient_session) == NOT_ATTENDING
  end

  def completed?(patient_session)
    status(patient_session) == COMPLETED
  end

  def status(patient_session)
    if all_programmes_have_outcome?(patient_session:)
      COMPLETED
    elsif attending_by_patient_session_id[patient_session.id]
      ATTENDING
    elsif attending_by_patient_session_id[patient_session.id] == false
      NOT_ATTENDING
    else
      UNKNOWN
    end
  end

  private

  attr_reader :patient_sessions

  def all_programmes_have_outcome?(patient_session:)
    patient_session.programmes.all? do
      key = [patient_session.patient_id, patient_session.session_id, it.id]
      vaccination_records.include?(key)
    end
  end

  def vaccination_records
    @vaccination_records ||=
      VaccinationRecord
        .kept
        .where(
          patient_id: patient_sessions.select(:patient_id),
          session_id: patient_sessions.select(:session_id)
        )
        .distinct
        .pluck(:patient_id, :session_id, :programme_id)
  end

  def attending_by_patient_session_id
    @attending_by_patient_session_id ||=
      Hash[
        SessionAttendance
          .where(patient_session: patient_sessions)
          .today
          .pluck(:patient_session_id, :attending)
      ]
  end
end
