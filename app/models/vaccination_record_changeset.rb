# frozen_string_literal: true

# Staging model for vaccination records during immunisation imports.
# Note: Backed by a future table `vaccination_record_changesets`.
# This skeleton is feature-flagged and currently unused unless the
# :immunisation_import_use_changesets flag is enabled.
class VaccinationRecordChangeset < ApplicationRecord
  self.table_name = "vaccination_record_changesets"

  # Associations are declared for completeness; the table/migrations will
  # be introduced alongside the full pipeline implementation.
  belongs_to :immunisation_import, optional: true
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

  # API placeholders — to be completed in subsequent steps.
  def self.from_import_row(row:, import:, row_number:, patient_changeset: nil)
    new
  end

  def assign_patient_id!(_patient_id)
    # In the full implementation this will persist and change state.
    true
  end

  def valid_for_commit?
    false
  end

  def to_vaccination_record_attributes
    {}
  end
end
