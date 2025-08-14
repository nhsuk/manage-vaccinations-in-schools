# frozen_string_literal: true

namespace :migrate_team do
  desc "Migrate Coventry to support flu."
  task coventry: :environment do |_, _args|
    TeamMigration::Coventry.call
  end
end
