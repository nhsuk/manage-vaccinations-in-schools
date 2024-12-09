# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"
gem "rails", "~> 7.2.2"

gem "activerecord-import"
gem "activerecord-session_store"
gem "amazing_print"
gem "audited", git: "https://github.com/tvararu/audited", branch: "encryption"
gem "bootsnap", require: false
gem "caxlsx"
gem "charlock_holmes"
gem "config"
gem "cssbundling-rails"
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
gem "jbuilder"
gem "jsbundling-rails"
gem "jsonb_accessor"
gem "jwt"
gem "mail-notify"
gem "notifications-ruby-client"
gem "okcomputer"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "pg", "~> 1.5"
gem "phonelib"
gem "propshaft"
gem "puma", "~> 6.5"
gem "pundit"
gem "rails_semantic_logger"
gem "rainbow"
gem "ruby-progressbar"
gem "rubyzip"
gem "sentry-rails"
gem "sentry-ruby"
gem "splunk-sdk-ruby"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "uk_postcode"
gem "wicked"
gem "with_advisory_lock"

group :development, :test do
  gem "brakeman"
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_instruments"
  gem "pry-rails"
  gem "rspec-rails"
end

group :development do
  gem "annotate", require: false
  gem "asciidoctor"
  gem "asciidoctor-diagram"
  gem "dockerfile-rails", ">= 1.0.0"
  gem "hotwire-livereload"
  gem "mechanize"
  gem "prettier_print", require: false
  gem "rails-erd"
  gem "rladr"
  gem "rubocop-govuk", require: false
  gem "rufo", require: false
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
  gem "syntax_tree", require: false
  gem "syntax_tree-haml", require: false
  gem "syntax_tree-rbs", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "capybara_accessible_selectors",
      git: "https://github.com/citizensadvice/capybara_accessible_selectors",
      branch: "main"
  gem "capybara-screenshot"
  gem "cuprite"
  gem "rspec"
  gem "rspec-html-matchers"
  gem "rubyXL"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webmock"
end
