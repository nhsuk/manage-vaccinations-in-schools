# frozen_string_literal: true

namespace :patient_team do
  namespace :update do
    desc "Update the patient-teams of all the patients and teams."
    task all: :environment do |_, _args|
      PatientTeamUpdater.call
    end

    desc "Update the patient-teams of a specific patient by ID."
    task :patient, [:id] => :environment do |_, args|
      Patient.find(args[:id])
      PatientTeamUpdater.call(patient:)
    end

    desc "Update the patient-teams of a specific team by workgroup."
    task :team, [:workgroup] => :environment do |_, args|
      Team.find_by!(workgroup: args[:workgroup])
      PatientTeamUpdater.call(team:)
    end
  end
end
