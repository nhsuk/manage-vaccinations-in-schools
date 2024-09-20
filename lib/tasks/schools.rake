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
      download_file.save("db/data/edubasealldata.zip")
      puts "File downloaded successfully to db/data/edubasealldata.zip"
    else
      puts "Download button never appeared, aborting"
    end
  end

  desc "Import schools from DfE GIAS CSV"
  task import: :environment do
    require "zip"
    require "ruby-progressbar"

    zip_file = Rails.root.join("db/data/edubasealldata.zip")
    puts "Starting schools import. Total locations: #{Location.count}"

    Zip::File.open(zip_file) do |zip|
      csv_entry = zip.glob("*.csv").first
      csv_content = csv_entry.get_input_stream.read

      total_rows = CSV.parse(csv_content).count - 1 # Subtract 1 for header
      batch_size = 1000
      locations = []

      # rubocop:disable Rails/SaveBang
      progress_bar =
        ProgressBar.create(
          total: total_rows,
          format: "%a %b\u{15E7}%i %p%% %t",
          progress_mark: " ",
          remainder_mark: "\u{FF65}"
        )
      # rubocop:enable Rails/SaveBang

      # Some URLs from the GIAS CSV are missing the protocol.
      process_url = ->(url) do
        return nil if url.blank?
        url.start_with?("http://", "https://") ? url : "https://#{url}"

        # Legh Vale school has a URL of http:www.leghvale.st-helens.sch.uk
        # which is not a valid URL.
        url.gsub!("http:www", "http://www")
      end

      CSV.parse(
        csv_content,
        headers: true,
        encoding: "ISO-8859-1:UTF-8"
      ) do |row|
        locations << Location.new(
          type: :school,
          urn: row["URN"],
          name: row["EstablishmentName"],
          address: [
            row["Street"],
            row["Locality"],
            row["Address3"]
          ].compact.join(", "),
          town: row["Town"],
          county: row["County (name)"],
          postcode: row["Postcode"],
          url: process_url.call(row["SchoolWebsite"].presence)
        )

        if locations.size >= batch_size
          Location.import! locations,
                           on_duplicate_key_update: {
                             conflict_target: [:urn],
                             columns: %i[name address town county postcode url]
                           }
          locations.clear
        end

        progress_bar.increment
      end

      # Import remaining locations in the last incomplete batch
      unless locations.empty?
        Location.import! locations,
                         on_duplicate_key_update: {
                           conflict_target: [:urn],
                           columns: %i[name address town county postcode url]
                         }
      end
    end

    puts "\nSchools import completed. Total locations: #{Location.count}"
  end

  desc "Add a school to a team."
  task :add_to_team, %i[team_id urn] => :environment do |_task, args|
    team = Team.find_by(id: args[:team_id])
    location = Location.school.find_by(urn: args[:urn])

    raise "Could not find location or team." if location.nil? || team.nil?

    unless location.team.nil?
      raise "School already belongs to #{location.team.name}."
    end

    location.update!(team:)
  end
end
