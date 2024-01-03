if Rails.env.production? && ENV["SKIP_PRODUCTION_CHECKS"].blank? &&
     ENV.fetch("SENTRY_DSN", "").blank?
  raise "Application is running in production mode but SENTRY_DSN is not set
    up. Please set up Sentry."
end
