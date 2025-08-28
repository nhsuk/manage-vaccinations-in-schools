# frozen_string_literal: true

require "active_support/parameter_filter"

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn

  config.breadcrumbs_logger = %i[
    active_support_logger
    http_logger
    sentry_logger
  ]

  config.traces_sample_rate = 0.01

  config.before_send_transaction =
    lambda do |event, _hint|
      if event.transaction == "/up" || event.transaction.starts_with?("/health")
        nil
      else
        event
      end
    end

  rails_filter_parameters =
    Rails.application.config.filter_parameters.map(&:to_s)

  sensitive_env_vars =
    ENV.select do |key, _v|
      rails_filter_parameters.any? do |parameter|
        key.downcase.include?(parameter)
      end
    end

  sensitive_values_pattern = Regexp.union(sensitive_env_vars.values)

  sensitive_value_filter = ->(key, value) do
    key_is_relevant = %i[value title].include?(key)

    if key_is_relevant && sensitive_values_pattern.match?(value)
      value.gsub!(sensitive_values_pattern, "[FILTERED]")
    end
  end

  combined_filter =
    ActiveSupport::ParameterFilter.new(
      Rails.application.config.filter_parameters + [sensitive_value_filter]
    )

  config.before_send =
    lambda do |event, hint|
      if !Rails.env.production? &&
           hint[:exception].is_a?(Notifications::Client::BadRequestError) &&
           hint[:exception].message.include?(
             "Can’t send to this recipient using a team-only API key"
           )
        nil
      else
        combined_filter.filter(event.to_hash)
      end
    end
end
