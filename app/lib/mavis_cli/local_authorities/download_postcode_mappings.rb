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
    class DownloadPostcodeMappings < Dry::CLI::Command
      desc "Download Postcode to Local Authority Best-Fit mappings from ONS"

      def call
        url =
          "https://www.arcgis.com/sharing/rest/content/items/7fc55d71a09d4dcfa1fd6473138aacc3/data"
        file_name = "ons-postcode-to-la-mappings.zip"

        puts "Downloading Postcode to Local Authority Best-Fit mappings from ONS"
        target_path = File.expand_path(File.join("db/data/", file_name))
        zip_data = Faraday.get(url).body
        bytes = File.write(target_path, zip_data)
        puts "#{bytes} bytes"
      end
    end
  end
  register "local-authorities" do |prefix|
    prefix.register "download-postcode-mappings",
                    LocalAuthorities::DownloadPostcodeMappings
  end
end
