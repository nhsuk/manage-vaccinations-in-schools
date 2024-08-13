# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.4"
gem "rails", "~> 7.1.3"

gem "activerecord-import"
gem "audited", git: "https://github.com/tvararu/audited", branch: "encryption"
gem "awesome_print"
gem "bootsnap", require: false
gem "config"
gem "cssbundling-rails"
gem "devise"
gem "devise-pwned_password"
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
gem "mail-notify"
gem "okcomputer"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pg", "~> 1.5"
gem "phonelib"
gem "propshaft"
gem "puma", "~> 6.4"
gem "pundit"
gem "rainbow"
gem "rubyzip"
gem "sentry-rails"
gem "sentry-ruby"
gem "silencer", require: false
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "uk_postcode"
gem "wicked"

group :development, :test do
  gem "brakeman"
  gem "debug", platforms: %i[mri mingw x64_mingw]
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
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end
