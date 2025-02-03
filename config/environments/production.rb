# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = {
    "cache-control" => "public, max-age=#{1.year.to_i}"
  }

  # Enable static file serving from the `/public` folder (turn off if using NGINX/Apache for it).
  config.public_file_server.enabled = true

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = {
    redirect: {
      exclude: ->(request) { request.path =~ /up/ }
    }
  }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = { request_id: :request_id }

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Don't log assets in production
  config.rails_semantic_logger.quiet_assets = true

  # Configure Semantic Logger to log to $STDOUT
  $stdout.sync = true
  config.rails_semantic_logger.add_file_appender = false
  config.semantic_logger.add_appender(
    io: $stdout,
    level: config.log_level,
    formatter: :json
  )

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    host:
      if Settings.is_review
        "#{ENV["HEROKU_APP_NAME"]}.herokuapp.com"
      else
        Settings.host
      end,
    protocol: "https"
  }

  # Configure GOV.UK Notify.
  config.action_mailer.delivery_method = :notify
  config.action_mailer.notify_settings = {
    api_key: Settings.govuk_notify.live_key
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.good_job.enable_cron = true
  config.good_job.cron = {
    bulk_update_patients_from_pds: {
      cron: "every hour",
      class: "BulkUpdatePatientsFromPDSJob",
      description: "Keep patient details up to date with PDS."
    },
    clinic_invitation: {
      cron: "every day at 9am",
      class: "ClinicSessionInvitationsJob",
      description: "Send school clinic invitation emails to parents"
    },
    consent_request: {
      cron: "every day at 9am",
      class: "SchoolConsentRequestsJob",
      description:
        "Send school consent request emails to parents for each session"
    },
    consent_reminder: {
      cron: "every day at 9am",
      class: "SchoolConsentRemindersJob",
      description:
        "Send school consent reminder emails to parents for each session"
    },
    session_reminder: {
      cron: "every day at 9am",
      class: "SchoolSessionRemindersJob",
      description: "Send school session reminder emails to parents"
    },
    remove_import_csv: {
      cron: "every day at 1am",
      class: "RemoveImportCSVJob",
      description: "Remove CSV data from old cohort and immunisation imports"
    },
    trim_active_record_sessions: {
      cron: "every day at 2am",
      class: "TrimActiveRecordSessionsJob",
      description: "Remove ActiveRecord sessions older than 30 days"
    },
    vaccination_confirmations: {
      cron: "every day at 7pm",
      class: "VaccinationConfirmationsJob",
      description: "Send vaccination confirmation emails to parents"
    }
  }
end
