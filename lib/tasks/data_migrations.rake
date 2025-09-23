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
end
