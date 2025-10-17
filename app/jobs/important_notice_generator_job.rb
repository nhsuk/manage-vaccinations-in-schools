# frozen_string_literal: true

class ImportantNoticeGeneratorJob < ApplicationJob
  queue_as :default

  def perform(patient = nil)
    if patient
      generate_notices_for_patient(patient)
    else
      Patient.find_each { |patient| generate_notices_for_patient(patient) }
    end
  end

  private

  def generate_notices_for_patient(patient)
    return unless patient.teams.any?

    patient.teams.each do |team|
      if patient.deceased? && !notice_exists?(patient, :deceased, team)
        ImportantNotice.create!(
          patient:,
          team_id: team.id,
          notice_type: :deceased,
          date_time: patient.date_of_death_recorded_at,
          message: "Record updated with child’s date of death",
          can_dismiss: true
        )
      end

      if patient.invalidated? && !notice_exists?(patient, :invalidated, team)
        ImportantNotice.create!(
          patient:,
          team_id: team.id,
          notice_type: :invalidated,
          date_time: patient.invalidated_at,
          message: "Record flagged as invalid",
          can_dismiss: false
        )
      end

      if patient.restricted? && !notice_exists?(patient, :restricted, team)
        ImportantNotice.create!(
          patient:,
          team_id: team.id,
          notice_type: :restricted,
          date_time: patient.restricted_at,
          message: "Record flagged as sensitive",
          can_dismiss: true
        )
      end

      generate_gillick_no_notify_notices(patient, team)

      # Dismiss any notices that are no longer relevant

      next if patient.invalidated?
      ImportantNotice
        .active(team:)
        .where(patient:, team_id: team.id, notice_type: :invalidated)
        .update_all(dismissed_at: Time.current)

      next if patient.restricted?
      ImportantNotice
        .active(team:)
        .where(patient:, team_id: team.id, notice_type: :restricted)
        .update_all(dismissed_at: Time.current)

      next if patient.deceased?
      ImportantNotice
        .active(team:)
        .where(patient:, team_id: team.id, notice_type: :deceased)
        .update_all(dismissed_at: Time.current)
    end
  end

  def generate_gillick_no_notify_notices(patient, team)
    no_notify_vaccination_records =
      patient
        .vaccination_records
        .includes(:programme)
        .joins(:team)
        .where(teams: { id: team.id }, notify_parents: false)

    return if no_notify_vaccination_records.empty?

    records_needing_notices =
      no_notify_vaccination_records.reject do |record|
        notice_exists?(
          patient,
          :gillick_no_notify,
          team,
          vaccination_record: record
        )
      end

    return if records_needing_notices.empty?

    records_needing_notices.each do |record|
      ImportantNotice.create!(
        patient:,
        team_id: team.id,
        vaccination_record_id: record.id,
        notice_type: :gillick_no_notify,
        date_time: record.performed_at,
        message:
          "Child gave consent for #{record.programme.name} " \
            "#{"vaccination".pluralize(1)} " \
            "under Gillick competence and does not want their parents to be notified. " \
            "These records will not be automatically synced with GP records. " \
            "Your team must let the child's GP know they were vaccinated.",
        can_dismiss: true
      )
    end
  end

  def notice_exists?(patient, notice_type, team, vaccination_record: nil)
    scope = ImportantNotice.where(patient:, notice_type:, team_id: team.id)

    if vaccination_record.present?
      scope.exists?(vaccination_record_id: vaccination_record.id)
    elsif notice_type == :restricted
      scope.where(
        "dismissed_at IS NULL OR dismissed_at >= ?",
        patient.restricted_at
      ).exists?
    elsif notice_type == :invalidated
      scope.where(
        "dismissed_at IS NULL OR dismissed_at >= ?",
        patient.invalidated_at
      ).exists?
    else
      scope.exists?
    end
  end
end
