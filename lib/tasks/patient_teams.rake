# frozen_string_literal: true

namespace :patient_teams do
  desc "Sync patient teams relationships"
  task sync: :environment do
    puts "Starting patient teams sync..."

    models = [PatientLocation, SchoolMove, ArchiveReason, VaccinationRecord]

    models.each do |model|
      puts "Processing #{model.name}..."
      begin
        model.all.insert_patient_teams_relationships
        puts "✓ Successfully synced #{model.name} with patient teams."
      rescue StandardError => e
        puts "✗ Error syncing #{model.name}: #{e.message}"
        raise e
      end
    end

    puts "Patient teams sync completed successfully!"
  end
end
