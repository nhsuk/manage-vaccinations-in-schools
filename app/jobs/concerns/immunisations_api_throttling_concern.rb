# frozen_string_literal: true

module ImmunisationsAPIThrottlingConcern
  extend ActiveSupport::Concern

  include Sidekiq::Job
  include Sidekiq::Throttled::Job

  included do
    sidekiq_throttle_as :immunisations_api

    retry_on Faraday::ServerError, wait: :polynomially_longer
  end
end
