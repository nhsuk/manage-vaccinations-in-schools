# frozen_string_literal: true

class ProcessPatientChangesetJob < ApplicationJob
  queue_as :imports

  def perform(patient_changeset)
    return if patient_changeset.processed?

    unique_nhs_number = get_unique_nhs_number(patient_changeset)
    if unique_nhs_number
      patient_changeset.child_attributes["nhs_number"] = unique_nhs_number
      patient_changeset.pds_nhs_number = unique_nhs_number
    end

    patient_changeset.processed!
    patient_changeset.save!

    if patient_changeset.import.changesets.pending.none?
      CommitPatientChangesetsJob.perform_async(
        patient_changeset.import.to_global_id.to_s
      )
    end
  end

  private

  def get_unique_nhs_number(patient_changeset)
    nhs_numbers =
      patient_changeset.search_results.pluck("nhs_number").compact.uniq
    nhs_numbers.count == 1 ? nhs_numbers.first : nil
  end
end
