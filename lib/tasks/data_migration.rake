# frozen_string_literal: true

namespace :data_migration do
  desc "Set the separate performed at date and time columns."
  task set_performed_at_date_and_time: :environment do
    VaccinationRecord.where(performed_at_date: nil).update_all(<<~SQL)
      performed_at_date = performed_at::date,
      performed_at_time = (performed_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/London')::time
    SQL
  end
end
