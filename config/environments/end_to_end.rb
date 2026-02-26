# frozen_string_literal: true

require_relative "development"

Rails.application.configure do
  config.enable_reloading = false # Don't reload code changes
  config.eager_load = true # Eager load code on boot for better performance

  config.web_console.development_only = false # Allow dev console on errors
  config.assets.compile = true # Allow Rails to serve assets dynamically
  config.assets.server = true # Enable the asset server middleware
end
