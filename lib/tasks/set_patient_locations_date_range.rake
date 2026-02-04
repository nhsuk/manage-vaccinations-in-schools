# frozen_string_literal: true

namespace :data_migration do
  desc "Set patient location date ranges to an unbounded range."
  task set_patient_locations_date_range: :environment do
    PatientLocation.where(date_range: nil).update_all(date_range: nil..nil)
  end
end
