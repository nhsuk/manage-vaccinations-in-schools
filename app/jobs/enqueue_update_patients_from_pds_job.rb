# frozen_string_literal: true

class EnqueueUpdatePatientsFromPDSJob < ApplicationJob
  queue_as :pds

  def perform
    scope = Patient.with_nhs_number.not_invalidated.not_deceased

    patients =
      scope
        .where(updated_from_pds_at: nil)
        .or(scope.where("updated_from_pds_at < ?", 12.hours.ago))
        .order("updated_from_pds_at ASC NULLS FIRST")

    UpdatePatientsFromPDS.call(patients, priority: 50, queue: :pds)
  end
end
