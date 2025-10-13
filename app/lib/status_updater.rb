# frozen_string_literal: true

class StatusUpdater
  def initialize(patient: nil, session: nil)
    scope = PatientLocation.joins_sessions

    scope = scope.where(patient:) if patient

    if session.is_a?(Session)
      scope = scope.where(sessions: { id: session.id })
    elsif session
      scope = scope.where(sessions: { id: session.pluck(:id) })
    end

    @patient_locations = scope
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

  attr_reader :patient_locations

  def update_consent_statuses!
    Patient::ConsentStatus.import!(
      %i[patient_id programme_id academic_year],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::ConsentStatus
      .where(patient: patient_locations.select(:patient_id))
      .includes(:consents, :patient, :programme, :vaccination_records)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::ConsentStatus.import!(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status vaccine_methods without_gelatine]
          }
        )
      end
  end

  def update_registration_statuses!
    Patient::RegistrationStatus.import!(
      %i[patient_id session_id],
      patient_location_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::RegistrationStatus
      .where(
        "(patient_id, session_id) IN (?)",
        patient_locations.select("patient_id", "sessions.id")
      )
      .includes(
        :patient,
        :attendance_records,
        :vaccination_records,
        session: :programmes
      )
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::RegistrationStatus.import!(
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
      .where(patient: patient_locations.select(:patient_id))
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
      .where(patient: patient_locations.select(:patient_id))
      .includes(
        :patient,
        :programme,
        :consents,
        :triages,
        :vaccination_records,
        :attendance_record
      )
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::VaccinationStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[
              status
              status_changed_at
              latest_location_id
              latest_session_status
            ]
          }
        )
      end
  end

  def academic_years
    @academic_years ||= AcademicYear.all
  end

  def patient_statuses_to_import
    @patient_statuses_to_import ||=
      patient_locations
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

  def patient_location_statuses_to_import
    patient_locations
      .joins(:patient)
      .pluck(
        "patients.id",
        "sessions.id",
        "sessions.location_id",
        "sessions.academic_year",
        "patients.birth_academic_year"
      )
      .filter_map do |patient_id, session_id, location_id, academic_year, birth_academic_year|
        year_group = birth_academic_year.to_year_group(academic_year:)

        if programme_ids_per_location_id_and_year_group
             .fetch(location_id, {})
             .fetch(year_group, [])
             .empty?
          next
        end

        [patient_id, session_id]
      end
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
        .pluck(:location_id, :programme_id, :year_group)
        .each_with_object({}) do |(location_id, programme_id, year_group), hash|
          hash[location_id] ||= {}
          hash[location_id][year_group] ||= []
          hash[location_id][year_group] << programme_id
        end
  end
end
