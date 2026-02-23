# frozen_string_literal: true

namespace :data_migration do
  desc "Backfills the `ConsentFormProgramme.disease_types` column for existing records"
  task backfill_consent_form_programme_disease_types: :environment do
    puts "Backfilling disease_types for ConsentFormProgramme records..."

    updated_count = 0
    skipped_count = 0

    ConsentFormProgramme.find_each do |consent_form_programme|
      if consent_form_programme.read_attribute(:disease_types).present?
        skipped_count += 1
        next
      end

      consent_form_programme.update_column(
        :disease_types,
        consent_form_programme.disease_types
      )
      updated_count += 1
    end

    puts "Updated: #{updated_count} records"
    puts "Skipped: #{skipped_count} records (already had disease_types set)"
  end
end
