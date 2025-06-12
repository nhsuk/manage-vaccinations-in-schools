# frozen_string_literal: true

module NHSAPIConcurrencyConcern
  extend ActiveSupport::Concern

  included do
    # NHS API imposes a limit of 5 requests per second
    # Rate limiting is handled by spacing out job execution using Sidekiq's built-in scheduling
    # Jobs are spaced out when enqueued to ensure we don't exceed the API rate limit

    # Handle NHS API's rate limiting responses
    retry_on Faraday::TooManyRequestsError,
             attempts: :unlimited,
             wait: ->(executions) { (executions * 5) + rand(0.5..5) }

    retry_on Faraday::ServerError, wait: :polynomially_longer
  end
end
