if Rails.env.production?
  # if credentials.dig(:active_record_encryption, :primary_key).blank?
  #   raise "Application is running in production mode but Active Record
  #   Encryption is not set up. Please set up Active Record Encryption. See
  #   https://edgeguides.rubyonrails.org/active_record_encryption.html"
  # end

  # if ENV.fetch("SENTRY_DSN", "").blank?
  #   raise "Application is running in production mode but SENTRY_DSN is not set
  #   up. Please set up Sentry."
  # end
end
