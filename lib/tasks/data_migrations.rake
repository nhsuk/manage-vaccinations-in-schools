# frozen_string_literal: true

namespace :data_migrations do
  desc "Ensure sessions have the right session programme year groups"
  task sync_location_programme_year_groups: :environment do
    Session.includes(:location_programme_year_groups).find_each(
      &:sync_location_programme_year_groups!
    )
  end
end
