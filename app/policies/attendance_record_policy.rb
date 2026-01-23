# frozen_string_literal: true

class AttendanceRecordPolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create?
    team.has_poc_only_access? && !already_vaccinated? && !was_seen_by_nurse?
  end

  def show? = team.has_poc_only_access?

  def update?
    team.has_poc_only_access? && !already_vaccinated? && !was_seen_by_nurse?
  end

  private

  delegate :patient, :location_id, :date, :session, to: :record

  delegate :academic_year, to: :session

  def already_vaccinated?
    session
      .programmes_for(patient:)
      .all? do |programme|
        patient.programme_status(programme, academic_year:).vaccinated?
      end
  end

  def was_seen_by_nurse?
    VaccinationRecord.kept.exists?(
      patient:,
      location_id:,
      performed_at_date: date
    )
  end
end
