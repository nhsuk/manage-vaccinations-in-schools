# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://pages.mysociety.org/uk_local_authority_names_and_codes/downloads/uk-la-future-uk-local-authorities-future-csv/latest
# 2. Click the "Download CSV" link
# 3. Download the csv file
# 4. Place it in db/data/uk-local-authorities.csv
#
# Alternatively, you can run this task.
require "open3"

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
        Open3.capture2("curl", "-o", target_path, url)

        row_count = Open3.capture2("wc", "-l", target_path).first.to_i
        puts "#{File.size(target_path)} bytes"
        puts "#{row_count} lines"
      end
    end
  end

  register "local_authorities" do |prefix|
    prefix.register "download", LocalAuthorities::Download
  end
end
