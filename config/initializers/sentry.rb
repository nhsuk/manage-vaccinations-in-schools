# frozen_string_literal: true

require "active_support/parameter_filter"

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn

  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  config.traces_sample_rate = 1.0

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
    lambda { |event, _hint| combined_filter.filter(event.to_hash) }
end
