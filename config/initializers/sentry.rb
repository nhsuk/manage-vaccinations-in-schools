require 'active_support/parameter_filter'

Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.traces_sample_rate = 1.0

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    filter.filter(event.to_hash)
  end
end
