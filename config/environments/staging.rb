# frozen_string_literal: true

require_relative "production"

Rails.application.configure { config.good_job.cron = CRON_JOBS }
