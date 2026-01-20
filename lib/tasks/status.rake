# frozen_string_literal: true

namespace :status do
  namespace :update do
    desc "Update the statuses of all the patients."
    task all: :environment do |_, _args|
      StatusUpdater.call
    end

    desc "Update the statuses of a specific patient by ID."
    task :patient, [:id] => :environment do |_, args|
      patient = Patient.find(args[:id])
      StatusUpdater.call(patient:)
    end
  end
end
