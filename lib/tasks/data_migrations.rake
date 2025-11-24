# frozen_string_literal: true

namespace :data_migrations do
  desc "Sets the team locations"
  task set_team_location: :environment do
    DataMigration::SetTeamLocation.call
  end
end
