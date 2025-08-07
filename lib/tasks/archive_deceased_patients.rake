# frozen_string_literal: true

desc "Migrate patients who are deceased to ensure they're archived."
task archive_deceased_patients: :environment do
  Patient
    .deceased
    .includes(:teams)
    .find_each do |patient|
      # We're using a private method here in this temporary task since we will
      # delete this task once it's been run in production.
      patient.send(:archive_due_to_deceased!)
    end
end
