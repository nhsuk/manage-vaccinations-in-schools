# frozen_string_literal: true

namespace :data_migration do
  desc "Backfills parent details on Consent records from their associated ConsentForm"
  task backfill_consent_parent_details: :environment do
    puts "Backfilling parent details for Consent records..."

    updated_count = 0
    skipped_count = 0
    no_consent_form_count = 0

    Consent
      .includes(:consent_form)
      .find_each do |consent|
        unless consent.consent_form
          no_consent_form_count += 1
          next
        end

        if consent.parent_full_name.present?
          skipped_count += 1
          next
        end

        consent.update_columns(
          parent_full_name: consent.consent_form.parent_full_name,
          parent_email: consent.consent_form.parent_email,
          parent_phone: consent.consent_form.parent_phone,
          parent_relationship_type:
            consent.consent_form.parent_relationship_type,
          parent_relationship_other_name:
            consent.consent_form.parent_relationship_other_name,
          parent_phone_receive_updates:
            consent.consent_form.parent_phone_receive_updates
        )
        updated_count += 1
      end

    puts "Updated: #{updated_count} records"
    puts "Skipped: #{skipped_count} records (already had parent_full_name set)"
    puts "No consent form: #{no_consent_form_count} records"
  end
end
