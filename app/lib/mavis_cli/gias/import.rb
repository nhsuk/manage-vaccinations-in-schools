#frozen_string_literal: true

module MavisCLI
  module GIAS
    class Import < Dry::CLI::Command
      desc "Import GIAS schools data"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/dfe-schools.zip",
             desc: "GIAS database file to use"

      def call(input_file:, **)
        MavisCLI.load_rails

        Zip::File.open(input_file) do |zip|
          csv_entry = zip.glob("edubasealldata*.csv").first
          csv_content = csv_entry.get_input_stream.read

          rows =
            CSV.parse(csv_content, headers: true, encoding: "ISO-8859-1:UTF-8")

          row_count = rows.length
          batch_size = 1000
          schools = []

          puts "Starting import of #{row_count} schools."
          progress_bar = MavisCLI.progress_bar(row_count + 1)

          rows.each do |row|
            gias_establishment_number = row["EstablishmentNumber"]
            next if gias_establishment_number.blank? # closed school that never opened

            schools << Location.new(
              type: :school,
              urn: row["URN"],
              gias_local_authority_code: row["LA (code)"],
              gias_establishment_number:,
              gias_year_groups: process_year_groups(row),
              name: row["EstablishmentName"],
              address_line_1: row["Street"],
              address_line_2: [
                row["Locality"],
                row["Address3"]
              ].compact_blank.join(", "),
              address_town: row["Town"],
              address_postcode: row["Postcode"],
              status: Integer(row["EstablishmentStatus (code)"]),
              url: process_url(row["SchoolWebsite"].presence)
            )

            if schools.size >= batch_size
              import_schools(schools)
              schools.clear
            end

            progress_bar.increment
          end

          import_schools(schools) unless schools.empty?
        end
      end

      def import_schools(schools)
        Location.import!(
          schools,
          on_duplicate_key_update: {
            conflict_target: %i[urn],
            index_predicate: "site IS NULL",
            columns: %i[
              address_line_1
              address_line_2
              address_postcode
              address_town
              gias_establishment_number
              gias_local_authority_code
              gias_year_groups
              name
              status
              url
            ]
          }
        )
      end

      # Some URLs from the GIAS CSV are missing the protocol.
      def process_url(url)
        return nil if url.blank?

        # Some school URLs don't start with http:// and https://
        url = url.start_with?("http://", "https://") ? url : "https://#{url}"

        # Legh Vale school has a URL of http:www.leghvale.st-helens.sch.uk
        # which is not a valid URL.
        url.gsub!("http:www", "http://www")
      end

      def process_year_groups(row)
        low_year_group = row["StatutoryLowAge"].to_i - 4
        high_year_group = row["StatutoryHighAge"].to_i - 5
        (low_year_group..high_year_group).to_a
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "import", GIAS::Import
  end
end
