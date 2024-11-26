# frozen_string_literal: true

class BulkUpdatePatientsFromPDSJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :pds

  good_job_control_concurrency_with perform_limit: 1

  def perform
    patients = Patient.with_nhs_number.not_invalidated.not_deceased

    GoodJob::Bulk.enqueue do
      patients
        .where(updated_from_pds_at: nil)
        .or(patients.where("updated_from_pds_at < ?", 6.hours.ago))
        .order("updated_from_pds_at ASC NULLS FIRST")
        .each_with_index do |patient, index|
          # Schedule with a delay to preemptively handle rate limit issues.
          # This shouldn't be necessary, but we're finding that Good Job
          # has occasional race condition issues, and spreading out the jobs
          # should reduce the risk of this.

          PatientUpdateFromPDSJob.set(
            priority: 50,
            wait: 0.21 * index
          ).perform_later(patient)
        end
    end
  end
end
