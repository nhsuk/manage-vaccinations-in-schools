# frozen_string_literal: true

namespace :schools do
  # To get the latest version of the zip:
  # 1. Go to https://get-information-schools.service.gov.uk/Downloads
  # 2. Check "Establishment fields CSV"
  # 3. Submit
  # 4. Download the zip file
  # 5. Place it in db/data/edubasealldata.zip
  #
  # Alternatively, you can run this task.
  desc "Download schools data"
  task download: :environment do
    require "mechanize"

    puts "Starting schools data download process..."
    agent = Mechanize.new

    puts "Visiting the downloads page"
    page = agent.get("https://get-information-schools.service.gov.uk/Downloads")

    puts "Checking the establishment fields CSV checkbox"
    form = page.form_with(action: "/Downloads/Collate")
    form.checkbox_with(id: "establishment-fields-csv-checkbox").check

    puts "Submitting the form"
    download_page = form.submit

    # There is a meta refresh on the download_page. Mechanize didn't seem to
    # follow it so we're just refreshing that page manually until the button shows
    # up below.
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
      download_file.save("db/data/edubasealldata.zip")
      puts "File downloaded successfully to db/data/edubasealldata.zip"
    else
      puts "Download button never appeared, abotting"
    end
  end
end
