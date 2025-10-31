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
    patient_locations.in_batches(of: 10_000) do |batch|
      Patient::ConsentStatus.import!(
        %i[patient_id programme_id academic_year],
        patient_statuses_to_import(batch),
        on_duplicate_key_ignore: true
      )

      consent_statuses =
        Patient::ConsentStatus
          .where(patient: batch.select(:patient_id))
          .includes(:consents, :patient, :programme, :vaccination_records)
          .to_a
      consent_statuses.each(&:assign_status)

      Patient::ConsentStatus.import!(
        consent_statuses,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: %i[status vaccine_methods without_gelatine]
        }
      )
    end
  end

  def update_registration_statuses!
    patient_locations.in_batches(of: 10_000) do |batch|
      Patient::RegistrationStatus.import!(
        %i[patient_id session_id],
        patient_location_statuses_to_import(batch),
        on_duplicate_key_ignore: true
      )

      registration_statuses =
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
          .to_a

      registration_statuses.each(&:assign_status)

      Patient::RegistrationStatus.import!(
        registration_statuses.select(&:changed?),
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: %i[status]
        }
      )
    end
  end

  def update_triage_statuses!
    patient_locations.in_batches(of: 10_000) do |batch|
      Patient::TriageStatus.import!(
        %i[patient_id programme_id academic_year],
        patient_statuses_to_import(batch),
        on_duplicate_key_ignore: true
      )

      triage_statuses =
        Patient::TriageStatus
          .where(patient: patient_locations.select(:patient_id))
          .includes(
            :patient,
            :programme,
            :consents,
            :triages,
            :vaccination_records
          )
          .to_a

      triage_statuses.each(&:assign_status)

      Patient::TriageStatus.import!(
        triage_statuses.select(&:changed?),
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: %i[status vaccine_method without_gelatine]
        }
      )
    end
  end

  def update_vaccination_statuses!
    patient_locations.in_batches(of: 10_000) do |batch|
      Patient::VaccinationStatus.import!(
        %i[patient_id programme_id academic_year],
        patient_statuses_to_import(batch),
        on_duplicate_key_ignore: true
      )

      vaccination_statuses =
        Patient::VaccinationStatus
          .where(patient: patient_locations.select(:patient_id))
          .includes(
            :attendance_record,
            :consents,
            :patient,
            :patient_locations,
            :programme,
            :triages,
            :vaccination_records
          )
          .to_a

      vaccination_statuses.each(&:assign_status)

      Patient::VaccinationStatus.import!(
        vaccination_statuses.select(&:changed?),
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

  def academic_years
    @academic_years ||= AcademicYear.all
  end

  def patient_statuses_to_import(batch = nil)
    batch ||= patient_locations
    @patient_statuses_to_import ||=
      batch
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

  def patient_location_statuses_to_import(batch = nil)
    batch ||= patient_locations

    batch
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
      Location::ProgrammeYearGroup
        .joins(:location_year_group)
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
