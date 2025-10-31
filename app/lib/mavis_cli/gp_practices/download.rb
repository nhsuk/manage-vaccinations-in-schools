# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://digital.nhs.uk/services/organisation-data-service/data-search-and-export/csv-downloads/gp-and-gp-practice-related-data
# 2. Download the zip file "epraccur"
# 3. Place it in db/data/nhs-gp-practices.zip
#
# Alternatively, you can run this task.

module MavisCLI
  module GPPractices
    class Download < Dry::CLI::Command
      desc "Download GP Practice data"

      option :output_file,
             aliases: ["-o"],
             default: "db/data/nhs-gp-practices.zip",
             desc: "file path to write GP practice database to"

      def call(output_file:, **)
        require "mechanize"

        puts "Starting GP practice data download process..."
        agent = Mechanize.new
        agent.user_agent_alias = "Mac Safari"

        puts "Visiting the downloads page"
        agent.get(
          "https://digital.nhs.uk/services/organisation-data-service/data-search-and-export/csv-downloads/gp-and-gp-practice-related-data"
        )

        puts "Download the GP practices data"
        epraccur_file = agent.click("epraccur")
        puts "Writing #{output_file}"
        epraccur_file.save!(output_file)
        puts "File downloaded successfully to #{output_file}"
      end
    end
  end

  register "gp-practices" do |prefix|
    prefix.register "download", GPPractices::Download
  end
end
