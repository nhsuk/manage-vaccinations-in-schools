# frozen_string_literal: true

# We need to patch the SplunkHttp appender to add the request channel header.
# Without this, Splunk returns a 400.
module SplunkHttpPatch
  def initialize(request_channel: nil, **args, &block)
    super(**args, &block)

    @header["X-Splunk-Request-Channel"] = request_channel if request_channel
  end
end

# Inject the "deploy_env" into the Splunk event. Because of how we use RAILS_ENV
# we need to add the deploy_env field to be able to differentiate between the
# different non-prod envs.
class MavisSplunkFormatter
  def call(log, logger)
    message = JSON.parse(logger.call(log, logger))
    message["event"]["deploy_env"] = Rails.configuration.deploy_env
    message.to_json
  end
end

SemanticLogger::Appender::SplunkHttp.prepend(SplunkHttpPatch)

if Settings.splunk.enabled
  SemanticLogger.add_appender(
    appender: :splunk_http,
    url: Settings.splunk.hec_endpoint,
    token: Settings.splunk.hec_token,
    request_channel: SecureRandom.uuid,
    formatter: MavisSplunkFormatter.new
  )
end
