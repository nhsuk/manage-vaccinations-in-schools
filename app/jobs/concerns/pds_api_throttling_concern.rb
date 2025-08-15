# frozen_string_literal: true

module PDSAPIThrottlingConcern
  extend ActiveSupport::Concern

  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  included do
    self.queue_adapter = :sidekiq unless Rails.env.test?

    sidekiq_throttle_as :pds

    retry_on Faraday::ServerError, wait: :polynomially_longer
  end
end
