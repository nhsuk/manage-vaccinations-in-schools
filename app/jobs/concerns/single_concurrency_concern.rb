# frozen_string_literal: true

module SingleConcurrencyConcern
  extend ActiveSupport::Concern

  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  included { sidekiq_throttle concurrency: { limit: 1, ttl: 1.hour.to_i } }
end
