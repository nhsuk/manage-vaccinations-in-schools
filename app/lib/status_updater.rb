# frozen_string_literal: true

class StatusUpdater
  def initialize(patient: nil, academic_years: nil)
    @patient = patient
    @academic_years = academic_years || AcademicYear.all
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

  attr_reader :patient, :academic_years

  def update_consent_statuses!
    Patient::ConsentStatus.import!(
      %i[patient_id programme_id programme_type academic_year],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::ConsentStatus
      .then { patient ? it.where(patient:) : it }
      .where(academic_year: academic_years)
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
      .joins(:session)
      .then { patient ? it.where(patient:) : it }
      .where(session: { academic_year: academic_years })
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
      %i[patient_id programme_id programme_type academic_year],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::TriageStatus
      .then { patient ? it.where(patient:) : it }
      .where(academic_year: academic_years)
      .includes(:patient, :programme, :consents, :triages, :vaccination_records)
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::TriageStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[status vaccine_method without_gelatine]
          }
        )
      end
  end

  def update_vaccination_statuses!
    Patient::VaccinationStatus.import!(
      %i[patient_id programme_id programme_type academic_year],
      patient_statuses_to_import,
      on_duplicate_key_ignore: true
    )

    Patient::VaccinationStatus
      .then { patient ? it.where(patient:) : it }
      .where(academic_year: academic_years)
      .includes(
        :attendance_record,
        :consents,
        :patient,
        :patient_locations,
        :programme,
        :triages,
        :vaccination_records
      )
      .find_in_batches(batch_size: 10_000) do |batch|
        batch.each(&:assign_status)

        Patient::VaccinationStatus.import!(
          batch.select(&:changed?),
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: %i[
              dose_sequence
              latest_date
              latest_location_id
              latest_session_status
              status
            ]
          }
        )
      end
  end

  def patient_statuses_to_import
    @patient_statuses_to_import ||=
      Patient
        .then { patient ? it.where(id: patient) : it }
        .pluck(:id, :birth_academic_year)
        .flat_map do |patient_id, birth_academic_year|
          academic_years.flat_map do |academic_year|
            year_group = birth_academic_year.to_year_group(academic_year:)

            programme_ids_per_year_group
              .fetch(year_group, [])
              .map do |programme_id|
                [
                  patient_id,
                  programme_id,
                  programme_types.fetch(programme_id),
                  academic_year
                ]
              end
          end
        end
  end

  def patient_location_statuses_to_import
    PatientLocation
      .joins(:patient)
      .joins_sessions
      .then { patient ? it.where(patient:) : it }
      .where(sessions: { academic_year: academic_years })
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

  def programme_types
    @programme_types ||= Programme.pluck(:id, :type).to_h
  end

  def programme_ids_per_year_group
    @programme_ids_per_year_group ||=
      Location::ProgrammeYearGroup
        .joins(:location_year_group)
        .where(location_year_group: { academic_year: academic_years })
        .distinct
        .pluck(:programme_id, :"location_year_group.value")
        .each_with_object({}) do |(programme_id, year_group), hash|
          hash[year_group] ||= []
          hash[year_group] << programme_id
        end
  end

  def programme_ids_per_location_id_and_year_group
    @programme_ids_per_location_id_and_year_group ||=
      Location::ProgrammeYearGroup
        .joins(:location_year_group)
        .where(location_year_group: { academic_year: academic_years })
        .pluck(
          :"location_year_group.location_id",
          :programme_id,
          :"location_year_group.value"
        )
        .each_with_object({}) do |(location_id, programme_id, year_group), hash|
          hash[location_id] ||= {}
          hash[location_id][year_group] ||= []
          hash[location_id][year_group] << programme_id
        end
  end
end
