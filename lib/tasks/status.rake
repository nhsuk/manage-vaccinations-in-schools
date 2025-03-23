# frozen_string_literal: true

namespace :status do
  namespace :update do
    desc "Update the statuses of all the patients."
    task all: :environment do |_, _args|
      StatusUpdater.call
    end

    desc "Update the statuses of a sessions the patient is in."
    task :patient, [:id] => :environment do |_, args|
      patient = Patient.find(args[:id])
      StatusUpdater.call(patient:)
    end

    desc "Update the statuses of all the patients in a session."
    task :session, [:slug] => :environment do |_, args|
      session = Session.find_by!(slug: args[:slug])
      StatusUpdater.call(session:)
    end
  end
end
