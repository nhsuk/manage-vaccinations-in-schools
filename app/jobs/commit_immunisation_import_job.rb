# frozen_string_literal: true

class CommitImmunisationImportJob
  include Sidekiq::Job

  queue_as :imports

  def perform(immunisation_import_id)
    import = ImmunisationImport.find_by(id: immunisation_import_id)
    return unless import

    counts = {
      new_record_count: 0,
      changed_record_count: 0,
      exact_duplicate_record_count: 0
    }

    imported_vaccination_record_ids = []
    linked_patients = Set.new
    linked_batches = Set.new
    imported_patient_location_ids = []

    VaccinationRecordChangeset
      .where(immunisation_import: import, status: :ready_to_commit)
      .find_in_batches(batch_size: 100) do |changesets|
        ActiveRecord::Base.transaction do
          changesets.each do |cs|
            record, created = upsert_vaccination_record_from_changeset(cs)
            imported_vaccination_record_ids << record.id
            linked_patients << record.patient
            linked_batches << record.batch if record.batch_id

            # Ensure patient location exists if session present
            if record.session_id
              pl = PatientLocation.find_or_initialize_by(
                patient_id: record.patient_id,
                location_id: record.session&.location_id,
                academic_year: record.academic_year
              )
              if pl.new_record?
                pl.save!
                imported_patient_location_ids << pl.id
              end
            end

            if created
              counts[:new_record_count] += 1
            else
              # As agreed: treat all conflicts/updates as changed for now.
              counts[:changed_record_count] += 1
            end

            # Minimal side-effect: notify already-had (idempotent by record)
            AlreadyHadNotificationSender.call(vaccination_record: record)

            cs.update_columns(
              status: VaccinationRecordChangeset.statuses[:committed],
              updated_at: Time.current
            )
          end
        end
      end

    # Link HABTM associations
    import.link_records_by_type(:vaccination_records, imported_vaccination_record_ids.map { |id| VaccinationRecord.new(id:) })
    import.link_records_by_type(:patients, linked_patients.to_a)
    import.link_records_by_type(:batches, linked_batches.to_a)
    import.link_records_by_type(
      :patient_locations,
      imported_patient_location_ids.map { |id| PatientLocation.new(id:) }
    )

    # Batch status update for patients touched
    StatusUpdater.call(patient: linked_patients.to_a)

    # Team sync + API sync mirroring legacy
    SyncPatientTeamJob.perform_later(VaccinationRecord, imported_vaccination_record_ids)
    SyncPatientTeamJob.perform_later(PatientLocation, imported_patient_location_ids)
    import.vaccination_records.where(id: imported_vaccination_record_ids).sync_all_to_nhs_immunisations_api

    import.update_columns(
      processed_at: Time.zone.now,
      status: :processed,
      **counts
    )
  end

  private

  # Returns [record, created_boolean]
  def upsert_vaccination_record_from_changeset(cs)
    attrs = build_attributes_from_changeset(cs)

    if cs.uuid.present?
      record = VaccinationRecord.find_or_initialize_by(uuid: cs.uuid)
      created = record.new_record?
      record.assign_attributes(attrs)
      record.save!
      return [record, created]
    end

    # Application-level dedupe on natural key: patient_id + programme_type + date
    date = cs.date_of_vaccination
    record =
      VaccinationRecord
        .where(patient_id: cs.patient_id, programme_type: cs.programme_type)
        .where(performed_at: date.beginning_of_day..date.end_of_day)
        .first

    if record
      created = false
      record.assign_attributes(attrs)
      record.save!
    else
      created = true
      record = VaccinationRecord.new({ uuid: SecureRandom.uuid }.merge(attrs))
      record.save!
    end

    [record, created]
  end

  def build_attributes_from_changeset(cs)
    payload = cs.payload || {}

    performed_at = cs.date_of_vaccination&.in_time_zone&.end_of_day

    base = {
      patient_id: cs.patient_id,
      programme_type: cs.programme_type,
      performed_at: performed_at,
      outcome: :administered,
      full_dose: true,
      source: :historical_upload
    }

    # Optional fields
    optional = {}
    optional[:dose_sequence] = payload["dose_sequence"] if payload.key?("dose_sequence")
    optional[:delivery_method] = payload["delivery_method"] if payload.key?("delivery_method")
    optional[:delivery_site] = payload["delivery_site"] if payload.key?("delivery_site")
    optional[:notes] = payload["notes"] if payload.key?("notes")
    optional[:performed_ods_code] = payload["performed_ods_code"] if payload.key?("performed_ods_code")
    optional[:session_id] = payload["session_id"] if payload.key?("session_id")
    optional[:batch_id] = payload["batch_id"] if payload.key?("batch_id")
    optional[:vaccine_id] = payload["vaccine_id"] if payload.key?("vaccine_id")

    # If recorded in service (session present), ensure protocol present
    if optional[:session_id].present?
      optional[:protocol] ||= :pgd
    end

    base.merge(optional)
  end
end
