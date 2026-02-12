# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://get-information-schools.service.gov.uk/Downloads
# 2. Check "Establishment fields CSV"
# 3. Check "Establishment links CSV"
# 4. Submit
# 5. Download the zip file
# 6. Move the downloaded file to db/data/dfe-schools.zip
#
# Alternatively, you can run this task.

module MavisCLI
  module GIAS
    class Download < Dry::CLI::Command
      desc "Download GIAS schools data"

      option :output_file,
             aliases: ["-o"],
             default: "db/data/dfe-schools.zip",
             desc: "file path to write GIAS database to"

      def call(output_file:, **)
        puts "Starting schools data download process..."
        if ::GIAS.download(output_file:)
          puts "File downloaded successfully to #{output_file}"
        else
          puts "Download button never appeared, aborting"
        end
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "download", GIAS::Download
  end
end
