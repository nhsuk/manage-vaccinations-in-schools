# frozen_string_literal: true

namespace :schools do
  # To get the latest version of the zip:
  # 1. Go to https://get-information-schools.service.gov.uk/Downloads
  # 2. Check "Establishment fields CSV"
  # 3. Submit
  # 4. Download the zip file
  # 5. Place it in db/data/dfe-schools.zip
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
      download_file.save("db/data/dfe-schools.zip")
      puts "File downloaded successfully to db/data/dfe-schools.zip"
    else
      puts "Download button never appeared, aborting"
    end
  end

  desc "Import schools from DfE GIAS CSV"
  task import: :environment do
    require "zip"
    require "ruby-progressbar"

    zip_file = Rails.root.join("db/data/dfe-schools.zip")
    puts "Starting schools import. Total locations: #{Location.school.count}"

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

      process_year_groups = ->(row) do
        low_year_group = row["StatutoryLowAge"].to_i - 4
        high_year_group = row["StatutoryHighAge"].to_i - 5
        (low_year_group..high_year_group).to_a
      end

      CSV.parse(
        csv_content,
        headers: true,
        encoding: "ISO-8859-1:UTF-8"
      ) do |row|
        gias_establishment_number = row["EstablishmentNumber"]
        next if gias_establishment_number.blank? # closed school that never opened

        locations << Location.new(
          type: :school,
          urn: row["URN"],
          gias_local_authority_code: row["LA (code)"],
          gias_establishment_number:,
          name: row["EstablishmentName"],
          address_line_1: row["Street"],
          address_line_2: [row["Locality"], row["Address3"]].compact_blank.join(
            ", "
          ),
          address_town: row["Town"],
          address_postcode: row["Postcode"],
          url: process_url.call(row["SchoolWebsite"].presence),
          year_groups: process_year_groups.call(row)
        )

        if locations.size >= batch_size
          Location.import! locations,
                           on_duplicate_key_update: {
                             conflict_target: [:urn],
                             columns: %i[
                               address_line_1
                               address_line_2
                               address_postcode
                               address_town
                               gias_establishment_number
                               gias_local_authority_code
                               name
                               url
                               year_groups
                             ]
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
                           columns: %i[
                             address_line_1
                             address_line_2
                             address_postcode
                             address_town
                             gias_establishment_number
                             gias_local_authority_code
                             name
                             url
                             year_groups
                           ]
                         }
      end
    end

    puts "\nSchools import completed. Total locations: #{Location.school.count}"
  end

  desc "Add a school to a organisation."
  task :add_to_organisation,
       %i[ods_code team_name] => :environment do |_task, args|
    organisation = Organisation.find_by(ods_code: args[:ods_code])

    raise "Could not find organisation." if organisation.nil?

    team = organisation.teams.find_by(name: args[:team_name])

    raise "Could not find team." if team.nil?

    args.extras.each do |urn|
      location = Location.school.find_by(urn:)

      if location.nil?
        puts "Could not find location: #{urn}"
        next
      end

      if !location.team_id.nil? && location.team_id != team.id
        puts "#{urn} previously belonged to #{location.team.name}"
      end

      location.update!(team:)
    end

    UnscheduledSessionsFactory.new.call
  end

  desc "Create a school for smoke testing in production."
  task smoke: :environment do
    Location.find_or_create_by!(
      name: "XXX Smoke Test School XXX",
      urn: "XXXXXX",
      type: :school,
      address_line_1: "1 Test Street",
      address_town: "Test Town",
      address_postcode: "TE1 1ST",
      gias_establishment_number: 999_999,
      gias_local_authority_code: 999_999,
      year_groups: [8, 9, 10, 11]
    )
  end
end
