# frozen_string_literal: true

class EnqueueUpdatePatientsFromPDSJob < ApplicationJob
  include SingleConcurrencyConcern

  queue_as :pds

  def perform
    scope =
      if Flipper.enabled?(:pds_cascading_search)
        Patient.not_deceased
      else
        Patient.with_nhs_number.not_deceased
      end

    patients =
      scope
        .where(updated_from_pds_at: nil)
        .or(scope.where("updated_from_pds_at < ?", 12.hours.ago))
        .order("updated_from_pds_at ASC NULLS FIRST")

    UpdatePatientsFromPDS.call(patients, queue: :pds)
  end
end
