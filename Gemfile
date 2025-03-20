# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"
gem "rails", "~> 8.0.1"

# Framework gems
gem "bootsnap", require: false
gem "cssbundling-rails"
gem "jsbundling-rails"
gem "pg"
gem "propshaft"
gem "puma"
gem "stimulus-rails"
gem "thruster", require: false
gem "turbo-rails"

# Load before sentry-ruby to avoid race condition
gem "stackprof"

# 3rd party gems
gem "activerecord-import"
gem "activerecord-session_store"
gem "amazing_print"
gem "audited", git: "https://github.com/tvararu/audited", branch: "encryption"
gem "caxlsx"
gem "charlock_holmes"
gem "config"
gem "csv"
gem "devise"
gem "discard"
gem "factory_bot_rails"
gem "faker"
gem "faraday"
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "good_job"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "govuk_markdown"
gem "jsonb_accessor"
gem "jwt"
gem "notifications-ruby-client"
gem "okcomputer"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "phonelib"
gem "pundit"
gem "rails_semantic_logger"
gem "rainbow"
gem "ruby-progressbar"
gem "rubyzip"
gem "sentry-rails"
gem "sentry-ruby"
gem "splunk-sdk-ruby"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "uk_postcode"
gem "wicked"
gem "with_advisory_lock"

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "factory_bot_instruments"
  gem "pry-rails"
  gem "rspec-rails"
end

group :development do
  gem "web-console"

  gem "annotaterb", require: false
  gem "asciidoctor"
  gem "asciidoctor-diagram"
  gem "aws-sdk-accessanalyzer", "~> 1"
  gem "aws-sdk-ec2", "~> 1"
  gem "aws-sdk-ecr", "~> 1"
  gem "aws-sdk-iam", "~> 1"
  gem "aws-sdk-rds", "~> 1"
  gem "aws-sdk-s3", "~> 1"
  gem "hotwire-livereload"
  gem "mechanize"
  gem "prettier_print", require: false
  gem "rladr"
  gem "rubocop-govuk", require: false
  gem "ruby-prof", require: false
  gem "rufo", require: false
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
  gem "syntax_tree", require: false
  gem "syntax_tree-haml", require: false
  gem "syntax_tree-rbs", require: false
end

group :test do
  gem "capybara"

  gem "capybara_accessible_selectors",
      git: "https://github.com/citizensadvice/capybara_accessible_selectors",
      branch: "main"
  gem "capybara-screenshot"
  gem "cuprite"
  gem "its"
  gem "rspec"
  gem "rspec-html-matchers"
  gem "rubyXL"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webmock"
end
