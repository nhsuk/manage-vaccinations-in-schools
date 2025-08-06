# frozen_string_literal: true

class SessionAttendancePolicy < ApplicationPolicy
  def create?
    super && !already_vaccinated? && !was_seen_by_nurse?
  end

  def update?
    super && !was_seen_by_nurse?
  end

  private

  delegate :patient_session, :session_date, to: :record

  def academic_year = patient_session.session.academic_year

  def already_vaccinated?
    patient_session.programmes.any? do |programme|
      patient_session
        .patient
        .vaccination_status(programme:, academic_year:)
        .vaccinated?
    end
  end

  def was_seen_by_nurse?
    VaccinationRecord.kept.exists?(
      patient_id: patient_session.patient_id,
      session_id: patient_session.session_id,
      performed_at: session_date.value.all_day
    )
  end
end
