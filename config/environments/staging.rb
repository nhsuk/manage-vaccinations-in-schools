# frozen_string_literal: true

require_relative "production"

Rails.application.configure do
  # Cron jobs will be handled by sidekiq-cron gem or external scheduler
end
