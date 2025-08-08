# frozen_string_literal: true

class UpdatePatientsFromPDS
  def initialize(patients, priority:, queue:)
    @patients = patients
    @priority = priority
    @queue = queue
  end

  def call
    return unless enqueue?

    GoodJob::Bulk.enqueue do
      jobs_queued = 0

      patients.find_each do |patient|
        # Schedule with a delay to preemptively handle rate limit issues.
        # This shouldn't be necessary, but we're finding that Good Job
        # has occasional race condition issues, and spreading out the jobs
        # should reduce the risk of this.

        if patient.nhs_number.nil?
          PatientNHSNumberLookupJob.set(
            priority:,
            queue:,
            wait: jobs_queued * wait_between_jobs
          ).perform_later(patient)
        else
          PatientUpdateFromPDSJob.set(
            priority:,
            queue:,
            wait: jobs_queued * wait_between_jobs
          ).perform_later(patient)
        end

        jobs_queued += 1

        if patient.pending_changes.present?
          PatientNHSNumberLookupWithPendingChangesJob.set(
            priority:,
            queue:,
            wait: jobs_queued * wait_between_jobs
          ).perform_later(patient)

          jobs_queued += 1
        end
      end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patients, :priority, :queue

  def settings
    @settings ||= Settings.pds
  end

  def enqueue?
    @enqueue ||= settings.enqueue_bulk_updates
  end

  def wait_between_jobs
    @wait_between_jobs ||= settings.wait_between_jobs.to_f
  end
end
