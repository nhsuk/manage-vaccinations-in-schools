# frozen_string_literal: true

require "sidekiq/throttled"

redis_config = { url: ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"] }

if Rails.env.production? || Rails.env.staging?
  redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  redis_config[:timeout] = 10
end

Sidekiq.configure_server { |config| config.redis = redis_config }

Sidekiq.configure_client { |config| config.redis = redis_config }

Sidekiq::Throttled.configure do |config|
  config.cooldown_period = 1.0
  config.cooldown_threshold = 1000
end

Sidekiq::Throttled::Registry.add(
  :immunisations_api,
  threshold: {
    limit: Settings.immunisations_api.rate_limit_per_second.to_i,
    period: 1.second
  }
)

# https://docs.notifications.service.gov.uk/rest-api.html#rate-limits
Sidekiq::Throttled::Registry.add(
  :notify,
  threshold: {
    limit: Settings.govuk_notify.rate_limit_per_second.to_i,
    period: 1.second
  }
)

Sidekiq::Throttled::Registry.add(
  :pds,
  threshold: {
    limit: Settings.pds.rate_limit_per_second.to_i,
    period: 1.second
  }
)
