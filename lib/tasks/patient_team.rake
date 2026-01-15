# frozen_string_literal: true

namespace :patient_team do
  namespace :update do
    desc "Update the patient-teams of all the patients and teams."
    task all: :environment do |_, _args|
      PatientTeamUpdater.call
    end

    desc "Update the patient-teams of a specific patient by ID."
    task :patient, [:id] => :environment do |_, args|
      patient_scope = Patient.where(id: args[:id])
      PatientTeamUpdater.call(patient_scope:)
    end

    desc "Update the patient-teams of a specific team by workgroup."
    task :team, [:workgroup] => :environment do |_, args|
      team_scope = Team.where(workgroup: args[:workgroup])
      PatientTeamUpdater.call(team_scope:)
    end
  end

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
