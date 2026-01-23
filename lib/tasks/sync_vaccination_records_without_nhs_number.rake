# frozen_string_literal: true

namespace :data_migration do
  desc "Sync vaccinations records for patients without NHS numbers"
  task sync_vaccination_records_without_nhs_number: :environment do
    Patient.without_nhs_number.find_each do |patient|
      patient.vaccination_records.sync_all_to_nhs_immunisations_api
    end
  end
end
