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
    if Flipper.enabled?(:import_review_screen)
      patient_changeset.calculating_review!
    else
      patient_changeset.committing!
    end

    if patient_changeset.import.changesets.pending.none?
      import = patient_changeset.import

      if Flipper.enabled?(:import_search_pds) &&
           Flipper.enabled?(:import_low_pds_match_rate)
        import.validate_pds_match_rate!
        return if import.low_pds_match_rate?
      end

      import.validate_changeset_uniqueness!
      return if import.changesets_are_invalid?

      unless Flipper.enabled?(:import_review_screen)
        CommitImportJob.perform_async(import.to_global_id.to_s)
        return
      end
    end

    if Flipper.enabled?(:import_review_screen)
      ReviewPatientChangesetJob.perform_later(patient_changeset.id)
    end
  end

  private

  def get_unique_nhs_number(patient_changeset)
    nhs_numbers =
      patient_changeset.search_results.pluck("nhs_number").compact.uniq
    nhs_numbers.count == 1 ? nhs_numbers.first : nil
  end
end
