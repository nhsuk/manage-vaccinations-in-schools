# frozen_string_literal: true

# Staging model for vaccination records during immunisation imports.
# Backed by the vaccination_record_changesets table (feature flagged usage).
class VaccinationRecordChangeset < ApplicationRecord
  self.table_name = "vaccination_record_changesets"

  belongs_to :immunisation_import
  belongs_to :patient_changeset, optional: true
  belongs_to :patient, optional: true

  enum :status,
       {
         from_file: 0,
         pending_patient: 1,
         ready_to_commit: 2,
         committing: 3,
         committed: 4,
         import_invalid: 5
       },
       validate: true

  validates :immunisation_import, presence: true
  validates :row_number, presence: true
  validates :programme_type, presence: true
  validates :date_of_vaccination, presence: true

  # Build a changeset from an import row. Does not require patient to be
  # resolved yet; that is set later via assign_patient_id!.
  def self.from_import_row(row:, import:, row_number:, patient_changeset: nil)
    create!(
      immunisation_import: import,
      row_number: row_number,
      status: :from_file,
      patient_changeset: patient_changeset,
      programme_type: row.programme&.type,
      date_of_vaccination: row.date_of_vaccination&.to_date,
      uuid: row.uuid&.to_s,
      payload: build_payload_from_row(row)
    )
  end

  def assign_patient_id!(patient_id)
    update!(patient_id: patient_id)
    if valid_for_commit?
      update!(status: :ready_to_commit)
    end
    true
  end

  def valid_for_commit?
    patient_id.present? && programme_type.present? && date_of_vaccination.present?
  end

  def to_vaccination_record_attributes
    {
      patient_id: patient_id,
      programme_type: programme_type,
      performed_at: date_of_vaccination&.in_time_zone&.beginning_of_day,
      outcome: :administered,
      full_dose: true,
      source: :historical_upload
    }.compact
  end

  class << self
    private

    # Minimal payload capture to allow future enrichment without coupling.
    def build_payload_from_row(row)
      {
        dose_sequence: row.dose_sequence_value,
        delivery_method: row.delivery_method_value,
        delivery_site: row.delivery_site_value,
        notes: row.notes&.to_s,
        performed_ods_code: row.performed_ods_code&.to_s,
        session_id: row.session&.id,
        batch_id: row.batch&.id,
        vaccine_id: row.vaccine&.id
      }.compact
    end
  end
end
