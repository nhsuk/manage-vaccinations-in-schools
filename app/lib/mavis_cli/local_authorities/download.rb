# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://pages.mysociety.org/uk_local_authority_names_and_codes/downloads/uk-la-future-uk-local-authorities-future-csv/latest
# 2. Click the "Download CSV" link
# 3. Download the csv file
# 4. Place it in db/data/uk-local-authorities.csv
#
# Alternatively, you can run this task.
require "faraday"

module MavisCLI
  module LocalAuthorities
    class Download < Dry::CLI::Command
      desc "Download MySociety UK Local Authorities list & GIAS codes"

      def call
        url =
          "https://pages.mysociety.org/uk_local_authority_names_and_codes/data/uk_la_future/latest/uk_local_authorities_future.csv"
        file_name = "uk-local-authorities.csv"

        puts "Downloading MySociety UK Local Authorities list"
        target_path = File.expand_path(File.join("db/data/", file_name))
        csv_data = Faraday.get(url).body
        row_count = csv_data.lines.count
        bytes = File.write(target_path, csv_data)
        puts "#{bytes} bytes, #{row_count} lines"
      end
    end
  end

  register "local-authorities" do |prefix|
    prefix.register "download", LocalAuthorities::Download
  end
end
