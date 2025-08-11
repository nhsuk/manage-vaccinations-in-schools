# frozen_string_literal: true

namespace :gp_practices do
  desc "Import GP practices from NHS data"
  task import: :environment do
    require "zip"
    require "ruby-progressbar"

    zip_file = Rails.root.join("db/data/nhs-gp-practices.zip")
    puts "Starting GP practices import. Total locations: #{Location.gp_practice.count}"

    Zip::File.open(zip_file) do |zip|
      csv_entry = zip.glob("*.csv").first
      csv_content = csv_entry.get_input_stream.read

      rows =
        CSV.parse(csv_content, headers: false, encoding: "ISO-8859-1:UTF-8")

      batch_size = 1000
      locations = []

      # rubocop:disable Rails/SaveBang
      progress_bar =
        ProgressBar.create(
          total: rows.length + 1,
          format: "%a %b\u{15E7}%i %p%% %t",
          progress_mark: " ",
          remainder_mark: "\u{FF65}"
        )
      # rubocop:enable Rails/SaveBang

      rows.each do |row|
        ods_code = row[0]
        name = row[1]
        address_line_1 = row[3]
        address_line_2 = row[4]
        address_town = row[5]
        address_postcode = row[9]

        locations << Location.new(
          type: :gp_practice,
          ods_code:,
          name:,
          address_line_1:,
          address_line_2:,
          address_town:,
          address_postcode:
        )

        if locations.size >= batch_size
          Location.import! locations,
                           on_duplicate_key_update: {
                             conflict_target: [:ods_code],
                             columns: %i[
                               address_line_1
                               address_line_2
                               address_postcode
                               address_town
                               name
                             ]
                           }
          locations.clear
        end

        progress_bar.increment
      end

      # Import remaining locations in the last incomplete batch
      unless locations.empty?
        Location.import! locations,
                         on_duplicate_key_update: {
                           conflict_target: [:ods_code],
                           columns: %i[
                             address_line_1
                             address_line_2
                             address_postcode
                             address_town
                             name
                           ]
                         }
      end
    end

    puts "\nGP practices import completed. Total locations: #{Location.gp_practice.count}"
  end

  desc "Create a GP practice for smoke testing in production."
  task smoke: :environment do
    Location.find_or_create_by!(
      name: "XXX Smoke Test GP XXX",
      ods_code: "Y90001", # https://digital.nhs.uk/developer/api-catalogue/personal-demographics-service-fhir/pds-fhir-api-test-data#production-smoke-testing
      type: :gp_practice
    )
  end
end
