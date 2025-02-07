# frozen_string_literal: true

class RateTestJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # around_perform :perform_with_counter

  good_job_control_concurrency_with perform_throttle: [5, 1.second],
                                    key: :nhs_api

  # Because the NHS API imposes a limit of 5 requests per second, we're almost
  # certain to hit throttling and the default exponential backoff strategy
  # appears to trigger more race conditions in the job performing code, meaning
  # there’s more instances where more than 5 requests are attempted.
  retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
           attempts: 1, # :unlimited,
           wait: ->(_) { rand(0.5..5) }

  retry_on Faraday::TooManyRequestsError,
           attempts: 2, # :unlimited,
           wait: ->(_) { rand(0.5..5) }

  retry_on Faraday::ServerError, wait: :polynomially_longer

  around_perform do |job, block|
    result = block.call
    if job.exception_executions.present?
      Rails.logger.error "Job #{job.job_id} exceptions: #{job.exception_executions}"
    end
    result
  end

  queue_as :test

  def perform(id:, batch:, wait: 0.1..0.5)
    patient = Patient.all.sample
    Patient.where(nhs_number: patient.nhs_number).count
    Patient.where(address_postcode: patient.address_postcode).count
    if wait.is_a? Range
      sleep(rand(wait))
    else
      sleep(wait)
    end
  end

  private

  def log_job_count
    Rails.logger.info "Current running #{self.class.name} jobs: #{count}"
  end
end
