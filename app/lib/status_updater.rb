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
    update_triage_statuses!
    update_vaccination_statuses!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient_sessions

  def update_consent_statuses!
    Patient::ConsentStatus.import!(
      %i[patient_id programme_id academic_year],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::ConsentStatus
      .where(patient: patient_sessions.select(:patient_id))
      .includes(:consents, :patient, :programme, :vaccination_records)
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
        :session_attendance,
        :vaccination_records,
        patient_session: {
          session: :programmes
        }
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

  def update_triage_statuses!
    Patient::TriageStatus.import!(
      %i[patient_id programme_id academic_year],
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
      %i[patient_id programme_id academic_year status_changed_at],
      vaccination_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::VaccinationStatus
      .where(patient: patient_sessions.select(:patient_id))
      .includes(
        :patient,
        :programme,
        :consents,
        :triages,
        :vaccination_records,
        :session_attendance
      )
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::VaccinationStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status latest_session_status status_changed_at]
          }
        )
      end
  end

  def academic_years
    @academic_years ||= AcademicYear.all
  end

  def patient_statuses_to_import
    @patient_statuses_to_import ||=
      patient_sessions
        .joins(:patient)
        .pluck(:patient_id, :"patients.birth_academic_year")
        .uniq
        .flat_map do |patient_id, birth_academic_year|
          academic_years.flat_map do |academic_year|
            year_group = birth_academic_year.to_year_group(academic_year:)

            programme_ids_per_year_group
              .fetch(year_group, [])
              .map { |programme_id| [patient_id, programme_id, academic_year] }
          end
        end
  end

  def vaccination_statuses_to_import
    status_changed_ats =
      AcademicYear.all.index_with do |academic_year|
        academic_year.to_academic_year_date_range.begin
      end

    patient_statuses_to_import.map do |row|
      [row[0], row[1], row[2], status_changed_ats.fetch(row[2])]
    end
  end

  def patient_session_statuses_to_import
    patient_sessions
      .joins(:patient, :session)
      .pluck(
        :id,
        :"session.location_id",
        :"session.academic_year",
        :"patients.birth_academic_year"
      )
      .flat_map do |patient_session_id, location_id, academic_year, birth_academic_year|
        year_group = birth_academic_year.to_year_group(academic_year:)

        programme_ids_per_location_id_and_year_group
          .fetch(location_id, {})
          .fetch(year_group, [])
          .map { [patient_session_id, it] }
      end
  end

  def registration_statuses_to_import
    patient_session_statuses_to_import.map { [it.first] }.uniq
  end

  def programme_ids_per_year_group
    @programme_ids_per_year_group ||=
      LocationProgrammeYearGroup
        .distinct
        .pluck(:programme_id, :year_group)
        .each_with_object({}) do |(programme_id, year_group), hash|
          hash[year_group] ||= []
          hash[year_group] << programme_id
        end
  end

  def programme_ids_per_location_id_and_year_group
    @programme_ids_per_location_id_and_year_group ||=
      LocationProgrammeYearGroup
        .distinct
        .pluck(:location_id, :programme_id, :year_group)
        .each_with_object({}) do |(location_id, programme_id, year_group), hash|
          hash[location_id] ||= {}
          hash[location_id][year_group] ||= []
          hash[location_id][year_group] << programme_id
        end
  end
end
