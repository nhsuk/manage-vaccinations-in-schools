# frozen_string_literal: true

# We need to patch the SplunkHttp appender to add the request channel header.
# Without this, Splunk returns a 400.
module SplunkHttpPatch
  def initialize(request_channel: nil, **args, &block)
    super(**args, &block)

    @header["X-Splunk-Request-Channel"] = request_channel if request_channel
  end
end

SemanticLogger::Appender::SplunkHttp.prepend(SplunkHttpPatch)

if Settings.splunk.enable
  SemanticLogger.add_appender(
    appender: :splunk_http,
    url: Settings.splunk.hec_endpoint,
    token: Settings.splunk.hec_token,
    request_channel: SecureRandom.uuid
  )
end
