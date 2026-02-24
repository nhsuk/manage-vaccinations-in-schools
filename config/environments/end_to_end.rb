# frozen_string_literal: true

require_relative "development"

Rails.application.configure do
  config.web_console.development_only = false # Allow dev console on errors
  config.assets.compile = true # Allow Rails to serve assets dynamically
  config.assets.server = true # Enable the asset server middleware
end
