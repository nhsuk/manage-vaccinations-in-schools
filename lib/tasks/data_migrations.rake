# frozen_string_literal: true

namespace :data_migrations do
  desc "Sets the programme type"
  task set_programme_type: :environment do
    DataMigration::SetProgrammeType.call
  end

  desc "Sets the session dates array column"
  task set_session_dates: :environment do
    DataMigration::SetSessionDates.call
  end
end
