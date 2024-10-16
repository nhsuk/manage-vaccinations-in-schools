# frozen_string_literal: true

module NHSAPIConcurrencyConcern
  extend ActiveSupport::Concern

  include GoodJob::ActiveJobExtensions::Concurrency

  included do
    # NHS API imposes a limit of 5 requests per second
    good_job_control_concurrency_with perform_limit: 5,
                                      perform_throttle: [5, 1.second],
                                      key: :nhs_api

    # Because the NHS API imposes a limit of 5 requests per second, we're almost
    # certain to hit throttling and the default exponential backoff strategy
    # appears to trigger more race conditions in the job performing code, meaning
    # there’s more instances where more than 5 requests are attempted.
    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
             attempts: :unlimited,
             wait: ->(_) { rand(0.5..5) }
  end
end
