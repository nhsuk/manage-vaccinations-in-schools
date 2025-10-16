# frozen_string_literal: true

namespace :data_migrations do
  desc "Mark vaccination records as synced to NHS Imms API"
  task mark_vaccination_records_as_synced: :environment do
    csv_data = File.read("db/data/imms-api-missing-record-ids.csv")

    rows = CSV.parse(csv_data, headers: true)
    rows.each do |row|
      vr = VaccinationRecord.find(row["mavis_id"])
      vr.update_columns(
        nhs_immunisations_api_synced_at: row["time"],
        nhs_immunisations_api_id: row["imms_api_id"],
        nhs_immunisations_api_etag: "1"
      )
    end
  end

  desc "Set nhs_immunisations_api_primary_source to true where nhs_immunisations_api_id is present"
  task set_api_primary_source: :environment do
    full_scope = VaccinationRecord.where.not(nhs_immunisations_api_id: nil)
    puts "Found #{full_scope.count} records with `nhs_immunisations_api_id` present."

    scope = full_scope.sourced_from_service
    puts "Found #{scope.count} vaccination_records with nhs_immunisations_api_id present and recorded in service."

    if full_scope.count != scope.count
      raise "Mismatch between `full_scope` and `scope`. This means there are some records which have an ID, " \
              "but weren't recorded in service"
    end

    to_update = scope.where(nhs_immunisations_api_primary_source: nil)
    puts "Setting nhs_immunisations_api_primary_source to true for #{to_update.count} records..."

    updated = to_update.update_all(nhs_immunisations_api_primary_source: true)
    puts "Updated #{updated} records."
  end
end
