# frozen_string_literal: true

class AttendanceRecordPolicy < ApplicationPolicy
  def create?
    !already_vaccinated? && !was_seen_by_nurse?
  end

  def update?
    !already_vaccinated? && !was_seen_by_nurse?
  end

  private

  delegate :patient, :session_date, to: :record
  delegate :session, to: :session_date
  delegate :academic_year, to: :session

  def already_vaccinated?
    session
      .programmes_for(patient:, academic_year:)
      .all? do |programme|
        patient.vaccination_status(programme:, academic_year:).vaccinated?
      end
  end

  def was_seen_by_nurse?
    VaccinationRecord.kept.exists?(
      patient:,
      session:,
      performed_at: session_date.value.all_day
    )
  end
end
