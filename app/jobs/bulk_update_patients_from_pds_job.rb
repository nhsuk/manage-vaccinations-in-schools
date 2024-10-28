# frozen_string_literal: true

class BulkUpdatePatientsFromPDSJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :pds

  good_job_control_concurrency_with perform_limit: 1

  def perform
    patients = Patient.with_nhs_number.not_invalidated.not_deceased

    patients
      .where(updated_from_pds_at: nil)
      .find_each { |patient| PatientUpdateFromPDSJob.perform_later(patient) }

    patients
      .where("updated_from_pds_at < ?", 6.hours.ago)
      .order(:updated_from_pds_at)
      .find_each { |patient| PatientUpdateFromPDSJob.perform_later(patient) }
  end
end
