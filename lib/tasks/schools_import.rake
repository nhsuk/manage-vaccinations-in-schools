# frozen_string_literal: true

namespace :schools do
  desc "Import schools from DfE GIAS CSV"
  task import: :environment do
    require "csv"

    csv_file = Rails.root.join("db/data/edubasealldata.csv")

    puts "Starting schools import. Total locations: #{Location.count}"

    total_rows = File.foreach(csv_file).count - 1 # Subtract 1 for header
    processed_rows = 0
    progress_bar_width = 50

    CSV.foreach(csv_file, headers: true, encoding: "ISO-8859-1:UTF-8") do |row|
      location = Location.find_or_initialize_by(urn: row["URN"])
      location.update!(
        name: row["EstablishmentName"],
        address: [row["Street"], row["Locality"], row["Address3"]].compact.join(
          ", "
        ),
        town: row["Town"],
        county: row["County (name)"],
        postcode: row["Postcode"],
        url: row["SchoolWebsite"]
      )

      # Update progress bar
      processed_rows += 1
      progress = (processed_rows.to_f / total_rows * progress_bar_width).to_i
      percent = (processed_rows.to_f / total_rows * 100).round(2)
      bar = "#" * progress + " " * (progress_bar_width - progress)
      print "\rProgress: #{processed_rows}/#{total_rows} [#{bar}] #{percent}%"
    end

    puts "\nSchools import completed. Total locations: #{Location.count}"
  end
end
