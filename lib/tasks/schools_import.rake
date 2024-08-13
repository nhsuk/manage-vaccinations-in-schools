# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://get-information-schools.service.gov.uk/Downloads
# 2. Check "Establishment fields CSV"
# 3. Submit
# 4. Download the zip file
# 5. Place it in db/data/edubasealldata.zip
namespace :schools do
  desc "Import schools from DfE GIAS CSV"
  task import: :environment do
    require "csv"
    require "zip"

    zip_file = Rails.root.join("db/data/edubasealldata.zip")
    puts "Starting schools import. Total locations: #{Location.count}"

    Zip::File.open(zip_file) do |zip|
      csv_entry = zip.glob("*.csv").first
      csv_content = csv_entry.get_input_stream.read

      total_rows = CSV.parse(csv_content).count - 1 # Subtract 1 for header
      processed_rows = 0
      progress_bar_width = 50
      batch_size = 1000
      locations = []

      CSV.parse(
        csv_content,
        headers: true,
        encoding: "ISO-8859-1:UTF-8"
      ) do |row|
        locations << Location.new(
          urn: row["URN"],
          name: row["EstablishmentName"],
          address: [
            row["Street"],
            row["Locality"],
            row["Address3"]
          ].compact.join(", "),
          town: row["Town"],
          county: row["County (name)"],
          postcode: row["Postcode"],
          url: row["SchoolWebsite"]
        )

        if locations.size >= batch_size
          Location.import locations,
                          on_duplicate_key_update: {
                            conflict_target: [:urn],
                            columns: %i[name address town county postcode url]
                          }
          locations.clear
        end

        # Update progress bar
        processed_rows += 1
        progress = (processed_rows.to_f / total_rows * progress_bar_width).to_i
        percent = (processed_rows.to_f / total_rows * 100).round(2)
        bar = "#" * progress + " " * (progress_bar_width - progress)
        print "\rProgress: #{processed_rows}/#{total_rows} [#{bar}] #{percent}%"
      end

      # Import remaining locations in the last incomplete batch
      unless locations.empty?
        Location.import locations,
                        on_duplicate_key_update: {
                          conflict_target: [:urn],
                          columns: %i[name address town county postcode url]
                        }
      end
    end

    puts "\nSchools import completed. Total locations: #{Location.count}"
  end
end
