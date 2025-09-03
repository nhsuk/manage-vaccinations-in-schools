# frozen_string_literal: true

module NotifyThrottlingConcern
  extend ActiveSupport::Concern

  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  included do
    self.queue_adapter = :sidekiq unless Rails.env.test?

    sidekiq_throttle_as :notify

    queue_as :notifications
  end
end
