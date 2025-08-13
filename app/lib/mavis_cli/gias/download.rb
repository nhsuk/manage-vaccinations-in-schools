# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://get-information-schools.service.gov.uk/Downloads
# 2. Check "Establishment fields CSV"
# 3. Submit
# 4. Download the zip file
# 5. Place it in db/data/dfe-schools.zip
#
# Alternatively, you can run this task.

module MavisCLI
  module GIAS
    class Download < Dry::CLI::Command
      desc "Download GIAS schools data"

      def call
        require "mechanize"

        puts "Starting schools data download process..."
        agent = Mechanize.new
        agent.user_agent_alias = "Mac Safari"

        puts "Visiting the downloads page"
        page =
          agent.get("https://get-information-schools.service.gov.uk/Downloads")

        puts "Checking the establishment fields CSV checkbox"
        form = page.form_with(action: "/Downloads/Collate")
        form.checkbox_with(id: "establishment-fields-csv-checkbox").check

        puts "Submitting the form"
        download_page = form.submit

        # There is a meta refresh on the download_page. Mechanize didn't seem to
        # follow it so we're just refreshing that page manually until the button
        # shows up below.
        wait_time = 0
        until (
                download_form =
                  download_page.form_with(action: "/Downloads/Download/Extract")
              ) || wait_time > 60
          puts "Waiting for the 'Results.zip' link to appear..."
          sleep(2)
          wait_time += 2
          download_page_uri = download_page.uri
          download_page = agent.get(download_page_uri)
        end

        if download_form
          download_button = download_form.button_with(value: "Results.zip")
          puts "'Results.zip' link found, downloading the file..."
          download_file = agent.click(download_button)
          puts "Overwriting db/data/dfe-schools.zip"
          download_file.save!("db/data/dfe-schools.zip")
          puts "File downloaded successfully to db/data/dfe-schools.zip"
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
