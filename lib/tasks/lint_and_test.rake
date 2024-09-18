# frozen_string_literal: true

desc "Run linters and tests"
task lint_and_test: :environment do
  puts "Running linters..."
  system("bin/lint") or abort("Linting failed!")

  puts "\nRunning tests..."
  system("bin/bundle exec rspec") or abort("Tests failed!")
end
