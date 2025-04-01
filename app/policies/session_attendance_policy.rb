# frozen_string_literal: true

class SessionAttendancePolicy < ApplicationPolicy
  def create?
    super && !was_seen_by_nurse?
  end

  def update?
    super && !was_seen_by_nurse?
  end

  private

  delegate :patient_session, :session_date, to: :record

  def was_seen_by_nurse?
    VaccinationRecord.kept.exists?(
      patient_id: patient_session.patient_id,
      session_id: patient_session.session_id,
      performed_at: session_date.value.all_day
    )
  end
end
