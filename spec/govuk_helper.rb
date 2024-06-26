# frozen_string_literal: true

require "view_component/test_helpers"

# require File.expand_path("dummy/config/environment", __dir__)

Dir[File.join("./spec", "govuk_shared", "*.rb")].sort.each do |file|
  require file
end

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include RSpecHtmlMatchers

  # config.include_context "helpers"
  config.include_context "setup"
end
