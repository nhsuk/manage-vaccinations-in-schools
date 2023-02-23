source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.0"
gem "rails", "~> 7.0.4"

gem "awesome_print"
gem "bootsnap", require: false
gem "config"
gem "cssbundling-rails"
gem "fhir_client"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "jbuilder"
gem "jsbundling-rails"
gem "okcomputer"
gem "pg", "~> 1.1"
gem "propshaft"
gem "puma", "~> 6.1"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "pry-rails"
end

group :development do
  gem "annotate", require: false
  gem "dockerfile-rails", ">= 1.0.0"
  gem "prettier_print", require: false
  gem "rladr"
  gem "rubocop-govuk", require: false
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
  gem "syntax_tree", require: false
  gem "syntax_tree-haml", require: false
  gem "syntax_tree-rbs", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "faker"
  gem "rspec"
  gem "rspec-rails"
  gem "webmock"
end
