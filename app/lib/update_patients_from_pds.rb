# frozen_string_literal: true

class UpdatePatientsFromPDS
  def initialize(patients, queue:)
    @patients = patients
    @queue = queue
  end

  def call
    return unless enqueue?

    GoodJob::Bulk.enqueue do
      patients.find_each.with_index do |patient, index|
        # Schedule with a delay to preemptively handle rate limit issues.
        # This shouldn't be necessary, but we're finding that Good Job
        # has occasional race condition issues, and spreading out the jobs
        # should reduce the risk of this.

        if patient.nhs_number.nil?
          PatientNHSNumberLookupJob.set(
            queue:,
            wait: index * wait_between_jobs
          ).perform_later(patient)
        else
          PatientUpdateFromPDSJob.set(
            queue:,
            wait: index * wait_between_jobs
          ).perform_later(patient)
        end
      end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patients, :queue

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
