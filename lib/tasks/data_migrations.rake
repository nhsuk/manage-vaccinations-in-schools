# frozen_string_literal: true

namespace :data_migrations do
  desc "Sets the programme type"
  task set_programme_type: :environment do
    DataMigration::SetProgrammeType.call
  end

  desc "Sets the location and date on Gillick assessments and pre-screenings"
  task set_location_and_date: :environment do
    DataMigration::SetLocationDate.call
  end
end
