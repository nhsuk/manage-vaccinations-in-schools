# frozen_string_literal: true

require "sidekiq"
require "sidekiq-cron"

# Helper method to convert Good Job cron syntax to standard cron
def convert_good_job_cron_to_sidekiq(good_job_cron)
  case good_job_cron
  when "every day at 1am"
    "0 1 * * *"
  when "every day at 2am"
    "0 2 * * *"
  when "every day at 3am"
    "0 3 * * *"
  when "every day at 4pm"
    "0 16 * * *"
  when "every day at 6:00 and 18:00"
    "0 6,18 * * *"
  when "every day at 9am"
    "0 9 * * *"
  when "every day at 13:00 and 16:00 and 19:00"
    "0 13,16,19 * * *"
  else
    # Default fallback - run daily at 2am
    "0 2 * * *"
  end
end

Sidekiq.configure_server do |config|
  redis_config = { url: ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"] }

  # Add SSL configuration for ElastiCache (self-designed cluster with TLS)
  if Rails.env.production? || Rails.env.staging?
    redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    redis_config[:timeout] = 10
  end

  config.redis = redis_config

  # Load cron jobs after Sidekiq server is ready
  config.on(:startup) do
    if Rails.env.production? || Rails.env.staging?
      require_relative "../cron_jobs"

      # Convert Good Job cron format to Sidekiq-cron format
      sidekiq_cron_jobs = {}
      CRON_JOBS.each do |name, job_config|
        # Convert "every day at 9am" to "0 9 * * *" format
        cron_expression = convert_good_job_cron_to_sidekiq(job_config[:cron])

        sidekiq_cron_jobs[name.to_s] = {
          "cron" => cron_expression,
          "class" => job_config[:class],
          "description" => job_config[:description]
        }
      end

      Sidekiq::Cron::Job.load_from_hash sidekiq_cron_jobs
      Rails.logger.info "Loaded #{sidekiq_cron_jobs.size} Sidekiq cron jobs"
    end
  end
end

Sidekiq.configure_client do |config|
  redis_config = { url: ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"] }

  # Add SSL configuration for ElastiCache (self-designed cluster with TLS)
  if Rails.env.production? || Rails.env.staging?
    redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    redis_config[:timeout] = 10
  end

  config.redis = redis_config
end

# Configure Sidekiq Web UI authentication
require "sidekiq/web"
require "sidekiq/cron/web"

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.support_username,
    username
  ) &&
    ActiveSupport::SecurityUtils.secure_compare(
      Rails.application.credentials.support_password,
      password
    )
end
