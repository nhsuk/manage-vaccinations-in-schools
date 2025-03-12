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
  delegate :patient, to: :patient_session

  def was_seen_by_nurse?
    patient.vaccination_records.any? do
      it.performed_at.to_date == session_date.value
    end
  end
end
