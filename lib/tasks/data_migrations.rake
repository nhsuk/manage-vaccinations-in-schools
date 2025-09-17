# frozen_string_literal: true

namespace :data_migrations do
  desc "Fix vaccination record locations where both location_id and location_name is set"
  task fix_vaccination_record_locations: :environment do
    vaccination_records =
      VaccinationRecord
        .where.not(location_id: nil)
        .where.not(location_name: nil)

    puts "#{vaccination_records.count} vaccination records need fixing"

    vaccination_records.update_all(location_id: nil)
  end
end
