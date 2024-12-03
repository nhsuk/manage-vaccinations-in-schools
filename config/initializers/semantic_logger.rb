# frozen_string_literal: true

SemanticLogger.add_appender(
  appender: :splunk_http,
  url: Settings.splunk.hec_endpoint,
  token: Settings.splunk.hec_token,
  index: Settings.splunk.index
)
