# frozen_string_literal: true

class UpdatePatientsFromPDS
  def initialize(patients, priority:, queue:)
    @patients = patients
    @priority = priority
    @queue = queue
  end

  def call
    return unless enqueue?

    patients.find_each.with_index do |patient, index|
      # Schedule with a delay to handle NHS API rate limiting.
      # Jobs are spaced out to ensure we don't exceed 5 requests per second.

      if patient.nhs_number.nil?
        PatientNHSNumberLookupJob.set(
          priority:,
          queue:,
          wait: index * wait_between_jobs
        ).perform_later(patient)
      else
        PatientUpdateFromPDSJob.set(
          priority:,
          queue:,
          wait: index * wait_between_jobs
        ).perform_later(patient)
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
