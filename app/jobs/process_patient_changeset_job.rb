# frozen_string_literal: true

class ProcessPatientChangesetJob < ApplicationJob
  queue_as :imports

  def perform(patient_changeset_id)
    patient_changeset = PatientChangeset.find(patient_changeset_id)
    return if patient_changeset.processed?

    unique_nhs_number = get_unique_nhs_number(patient_changeset)
    if unique_nhs_number
      patient_changeset.child_attributes["nhs_number"] = unique_nhs_number
      patient_changeset.pds_nhs_number = unique_nhs_number
    end

    patient_changeset.assign_patient_id
    patient_changeset.save!

    patient_changeset.calculating_review!

    if patient_changeset.import.changesets.pending.none?
      # check PDS match rate
      if Flipper.enabled?(:import_low_pds_match_rate)
        import.validate_pds_match_rate!
        return if patient_changeset.import.low_pds_match_rate?
      end

      # check no duplicate patients in import
      patient_changeset.import.validate_rows_are_unique!
      return if patient_changeset.import.rows_are_invalid?
    end

    ReviewPatientChangesetJob.perform_later(patient_changeset)
  end

  private

  def get_unique_nhs_number(patient_changeset)
    nhs_numbers =
      patient_changeset.search_results.pluck("nhs_number").compact.uniq
    nhs_numbers.count == 1 ? nhs_numbers.first : nil
  end
end
