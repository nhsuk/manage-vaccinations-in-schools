# frozen_string_literal: true

desc "Migrate teams"
task :migrate_teams, [:id] => :environment do |_, _args|
  TeamMigration::Leicestershire.call
  TeamMigration::Coventry.call
  TeamMigration::EastOfEngland.call
end
