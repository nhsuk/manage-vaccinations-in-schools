# frozen_string_literal: true

class ReviewPatientChangesetJob < ApplicationJob
  queue_as :imports

  def perform(patient_changeset_id)
    patient_changeset = PatientChangeset.find(patient_changeset_id)
    if patient_changeset.ready_for_review? || patient_changeset.import_invalid?
      return
    end

    patient_changeset.calculate_review_data!
    patient_changeset.ready_for_review!

    import = patient_changeset.import

    unless import.changesets.calculating_review.any? ||
             import.changesets.import_invalid.any?
      if import.is_a?(ClassImport)
        ReviewClassImportSchoolMoveJob.perform_later(import.id)
      else
        import.in_review!
      end
    end
  end
end
