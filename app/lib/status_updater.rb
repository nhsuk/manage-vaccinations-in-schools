# frozen_string_literal: true

class StatusUpdater
  def initialize(patient: nil, session: nil)
    scope = PatientSession

    scope = scope.where(patient:) if patient
    scope = scope.where(session:) if session

    @patient_sessions = scope
  end

  def call
    update_consent_statuses!
    update_registration_statuses!
    update_session_statuses!
    update_triage_statuses!
    update_vaccination_statuses!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient_sessions

  def update_consent_statuses!
    Patient::ConsentStatus.import!(
      %i[patient_id programme_id],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::ConsentStatus
      .where(patient: patient_sessions.select(:patient_id))
      .includes(:consents)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::ConsentStatus.import!(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status vaccine_methods]
          }
        )
      end
  end

  def update_registration_statuses!
    PatientSession::RegistrationStatus.import!(
      %i[patient_session_id],
      registration_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    PatientSession::RegistrationStatus
      .where(patient_session_id: patient_sessions.select(:id))
      .includes(
        :patient,
        :session_attendance,
        :vaccination_records,
        session: :programmes
      )
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        PatientSession::RegistrationStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status]
          }
        )
      end
  end

  def update_session_statuses!
    PatientSession::SessionStatus.import!(
      %i[patient_session_id programme_id],
      patient_session_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    PatientSession::SessionStatus
      .where(patient_session_id: patient_sessions.select(:id))
      .includes(:consents, :triages, :vaccination_records, :session_attendance)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        PatientSession::SessionStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status]
          }
        )
      end
  end

  def update_triage_statuses!
    Patient::TriageStatus.import!(
      %i[patient_id programme_id],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::TriageStatus
      .where(patient: patient_sessions.select(:patient_id))
      .includes(:patient, :programme, :consents, :triages, :vaccination_records)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::TriageStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status vaccine_method]
          }
        )
      end
  end

  def update_vaccination_statuses!
    Patient::VaccinationStatus.import!(
      %i[patient_id programme_id],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::VaccinationStatus
      .where(patient: patient_sessions.select(:patient_id))
      .includes(:patient, :programme, :consents, :triages, :vaccination_records)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::VaccinationStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status]
          }
        )
      end
  end

  def patient_statuses_to_import
    @patient_statuses_to_import ||=
      patient_sessions
        .joins(:patient)
        .pluck(:patient_id, :"patients.birth_academic_year")
        .uniq
        .flat_map do |patient_id, birth_academic_year|
          programme_ids_per_year_group
            .fetch(birth_academic_year.to_year_group, [])
            .map { [patient_id, it] }
        end
  end

  def patient_session_statuses_to_import
    @patient_session_statuses_to_import ||=
      patient_sessions
        .joins(:patient, :session)
        .pluck(:id, :"session.location_id", :"patients.birth_academic_year")
        .flat_map do |patient_session_id, location_id, birth_academic_year|
          programme_ids_per_location_id_and_year_group
            .fetch(location_id, {})
            .fetch(birth_academic_year.to_year_group, [])
            .map { [patient_session_id, it] }
        end
  end

  def registration_statuses_to_import
    @registration_statuses_to_import ||=
      patient_session_statuses_to_import.map { [it.first] }.uniq
  end

  def programme_ids_per_year_group
    @programme_ids_per_year_group ||=
      Location::ProgrammeYearGroup
        .distinct
        .pluck(:programme_id, :year_group)
        .each_with_object({}) do |(programme_id, year_group), hash|
          hash[year_group] ||= []
          hash[year_group] << programme_id
        end
  end

  def programme_ids_per_location_id_and_year_group
    @programme_ids_per_location_id_and_year_group ||=
      Location::ProgrammeYearGroup
        .distinct
        .pluck(:location_id, :programme_id, :year_group)
        .each_with_object({}) do |(location_id, programme_id, year_group), hash|
          hash[location_id] ||= {}
          hash[location_id][year_group] ||= []
          hash[location_id][year_group] << programme_id
        end
  end
end
