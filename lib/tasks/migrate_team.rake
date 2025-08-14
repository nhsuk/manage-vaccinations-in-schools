# frozen_string_literal: true

namespace :migrate_team do
  desc "Migrate Coventry to support flu."
  task coventry: :environment do |_, _args|
    TeamMigration::Coventry.call
  end

  desc "Migrate Leicestershire to support flu."
  task leicestershire: :environment do |_, _args|
    TeamMigration::Leicestershire.call
  end
end
