# frozen_string_literal: true

class ImportantNoticeGeneratorJob < ApplicationJob
  queue_as :cache

  BATCH_SIZE = 1000

  def perform(patient_ids = nil)
    if patient_ids.present?
      process_batch(
        Patient.includes(:teams, vaccination_records: %i[team]).where(
          id: patient_ids
        )
      )
    else
      Patient
        .includes(:teams, vaccination_records: %i[team])
        .find_in_batches(batch_size: BATCH_SIZE) do |patients_batch|
          process_batch(patients_batch)
        end
    end
  end

  private

  def process_batch(patients)
    notices_to_create = []
    notice_ids_to_dismiss = []

    patient_ids = patients.map(&:id)

    existing_notices =
      ImportantNotice.where(patient_id: patient_ids).index_by { notice_key(it) }

    patient_team_ids =
      patients.each_with_object({}) do |patient, hash|
        hash[patient.id] = patient.teams.map(&:id)
      end

    patients.each do |patient|
      collect_notices_for_patient(
        patient,
        notices_to_create,
        notice_ids_to_dismiss,
        existing_notices,
        patient_team_ids[patient.id]
      )
    end

    if notices_to_create.any?
      ImportantNotice.import!(notices_to_create, on_duplicate_key_ignore: true)
    end

    if notice_ids_to_dismiss.any?
      ImportantNotice.where(id: notice_ids_to_dismiss).update_all(
        dismissed_at: Time.current
      )
    end
  end

  def collect_notices_for_patient(
    patient,
    notices_to_create,
    notice_ids_to_dismiss,
    existing_notices,
    team_ids
  )
    return if team_ids.empty?

    team_ids.each do |team_id|
      if patient.deceased? &&
           !notice_exists?(existing_notices, patient.id, :deceased, team_id)
        notices_to_create << ImportantNotice.new(
          patient:,
          team_id: team_id,
          type: :deceased,
          recorded_at: patient.date_of_death_recorded_at
        )
      end

      if patient.invalidated? &&
           !notice_exists?(existing_notices, patient.id, :invalidated, team_id)
        notices_to_create << ImportantNotice.new(
          patient:,
          team_id: team_id,
          type: :invalidated,
          recorded_at: patient.invalidated_at
        )
      end

      if patient.restricted? &&
           !notice_exists?(existing_notices, patient.id, :restricted, team_id)
        notices_to_create << ImportantNotice.new(
          patient:,
          team_id: team_id,
          type: :restricted,
          recorded_at: patient.restricted_at
        )
      end

      collect_gillick_no_notify_notices(
        patient,
        team_id,
        notices_to_create,
        existing_notices
      )

      team_changed_notices = patient.important_notices.team_changed.any?
      if team_changed_notices
        notice_ids_to_dismiss << team_changed_notices.where(
          team: patient.school.teams
        ).ids
      end

      unless patient.invalidated?
        existing_notices.each_value do |notice|
          unless notice.patient_id == patient.id && notice.team_id == team_id &&
                   notice.type == "invalidated" && notice.dismissed_at.nil?
            next
          end
          notice_ids_to_dismiss << notice.id
        end
      end

      unless patient.restricted?
        existing_notices.each_value do |notice|
          unless notice.patient_id == patient.id && notice.team_id == team_id &&
                   notice.type == "restricted" && notice.dismissed_at.nil?
            next
          end
          notice_ids_to_dismiss << notice.id
        end
      end

      next if patient.deceased?
      existing_notices.each_value do |notice|
        unless notice.patient_id == patient.id && notice.team_id == team_id &&
                 notice.type == "deceased" && notice.dismissed_at.nil?
          next
        end
        notice_ids_to_dismiss << notice.id
      end
    end
  end

  def collect_gillick_no_notify_notices(
    patient,
    team_id,
    notices_to_create,
    existing_notices
  )
    no_notify_vaccination_records =
      patient.vaccination_records.select do |record|
        record.team&.id == team_id && record.notify_parents == false
      end

    return if no_notify_vaccination_records.empty?

    no_notify_vaccination_records.each do |record|
      if notice_exists?(
           existing_notices,
           patient.id,
           :gillick_no_notify,
           team_id,
           record.id
         )
        next
      end

      notices_to_create << ImportantNotice.new(
        patient:,
        team_id: team_id,
        vaccination_record_id: record.id,
        type: :gillick_no_notify,
        recorded_at: record.performed_at
      )
    end
  end

  def notice_key(notice)
    [
      notice.patient_id,
      notice.type,
      notice.team_id,
      notice.vaccination_record_id
    ]
  end

  def notice_exists?(
    existing_notices,
    patient_id,
    type,
    team_id,
    vaccination_record_id = nil
  )
    key = [patient_id, type.to_s, team_id, vaccination_record_id]
    existing_notices.key?(key)
  end
end
