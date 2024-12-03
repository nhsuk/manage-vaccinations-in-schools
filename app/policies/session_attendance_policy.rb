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
    patient_session
      .vaccination_records
      .where(performed_at: session_date.value.all_day)
      .exists?
  end
end
