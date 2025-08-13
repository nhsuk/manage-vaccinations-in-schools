# frozen_string_literal: true

module NHSAPIConcurrencyConcernGoodJob
  extend ActiveSupport::Concern

  include GoodJob::ActiveJobExtensions::Concurrency

  included do
    # NHS API imposes a limit of 5 requests per second
    good_job_control_concurrency_with(
      perform_throttle: [concurrent_jobs_per_second, 1.second],
      key: concurrency_key
    )

    # Because the NHS API imposes a limit of 5 requests per second, we're almost
    # certain to hit throttling and the default exponential backoff strategy
    # appears to trigger more race conditions in the job performing code, meaning
    # there’s more instances where more than 5 requests are attempted.
    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
             attempts: :unlimited,
             wait: ->(executions) do
               (executions * concurrent_jobs_per_second) + rand(0.5..5)
             end

    retry_on Faraday::TooManyRequestsError,
             attempts: :unlimited,
             wait: ->(executions) do
               (executions * concurrent_jobs_per_second) + rand(0.5..5)
             end

    retry_on Faraday::ServerError, wait: :polynomially_longer
  end
end
