# frozen_string_literal: true

namespace :db do
  namespace :prepare do
    desc "Run db:prepare but ignore ActiveRecord::ConcurrentMigrationError errors"
    task ignore_concurrent_migration_exceptions: :environment do
      Rake::Task["db:prepare"].invoke
    rescue ActiveRecord::ConcurrentMigrationError
      # Do nothing
    end
  end
end
