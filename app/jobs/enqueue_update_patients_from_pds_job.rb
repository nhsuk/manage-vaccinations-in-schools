# frozen_string_literal: true

class EnqueueUpdatePatientsFromPDSJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :pds

  good_job_control_concurrency_with perform_limit: 1

  def perform
    scope = Patient.with_nhs_number.not_invalidated.not_deceased

    patients =
      scope
        .where(updated_from_pds_at: nil)
        .or(scope.where("updated_from_pds_at < ?", 12.hours.ago))
        .order("updated_from_pds_at ASC NULLS FIRST")

    UpdatePatientsFromPDS.call(patients, queue: :pds)
  end
end
