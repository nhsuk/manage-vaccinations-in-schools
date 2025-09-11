# frozen_string_literal: true

module SingleConcurrencyConcern
  extend ActiveSupport::Concern

  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  included { sidekiq_throttle concurrency: { limit: 1 } }
end
