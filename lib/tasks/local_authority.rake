# frozen_string_literal: true

namespace :local_authority do
  desc "Backfill local_authority_mhclg_code on patients (one-time)"
  task backfill_patients: :environment do
    scope = Patient.where(local_authority_mhclg_code: nil)
    total = scope.count
    puts "Checking #{total} patients..."

    processed = 0
    updated = 0
    skipped_no_postcode = 0
    skipped_no_match = 0

    scope.find_each do |patient|
      processed += 1
      next skipped_no_postcode += 1 if patient.address_postcode.blank?

      la_code =
        LocalAuthority.for_postcode(patient.address_postcode)&.mhclg_code
      if la_code
        patient.update_column(:local_authority_mhclg_code, la_code)
        updated += 1
      else
        skipped_no_match += 1
      end

      if (processed % 10_000).zero?
        puts "Processed #{processed}/#{total} (updated: #{updated})"
      end
    end

    puts "Done. Processed #{processed} patients."
    puts "  Updated: #{updated}"
    puts "  Skipped (no postcode): #{skipped_no_postcode}"
    puts "  Skipped (no LA match): #{skipped_no_match}"
  end
end
