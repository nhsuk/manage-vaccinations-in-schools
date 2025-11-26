#frozen_string_literal: true

module MavisCLI
  module GPPractices
    class Import < Dry::CLI::Command
      desc "Import NHS GP Practice data"

      option :input_file,
             aliases: ["-f"],
             default: "db/data/nhs-gp-practices.csv",
             desc: "NHS GP Practice database file to use"

      def call(input_file:, **)
        MavisCLI.load_rails

        File.open(input_file) do |file|
          rows =
            CSV.parse(file.read, headers: false, encoding: "ISO-8859-1:UTF-8")

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
              import_gp_practices(locations)
              locations.clear
            end

            progress_bar.increment
          end

          # Import remaining locations in the last incomplete batch
          import_gp_practices(locations) unless locations.empty?
        end
      end

      def import_gp_practices(gp_practices)
        Location.import!(
          gp_practices,
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
        )
      end
    end
  end

  register "gp-practices" do |prefix|
    prefix.register "import", GPPractices::Import
  end
end
