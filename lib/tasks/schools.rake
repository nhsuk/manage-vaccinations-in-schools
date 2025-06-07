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
      puts "Overwriting db/data/dfe-schools.zip"
      download_file.save!("db/data/dfe-schools.zip")
      puts "File downloaded successfully to db/data/dfe-schools.zip"
    else
      puts "Download button never appeared, aborting"
    end
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

  desc "Transfer child records from one school to another."
  task :move_patients, %i[old_urn new_urn] => :environment do |_task, args|
    old_loc = Location.school.find_by(urn: args[:old_urn])
    new_loc = Location.school.find_by(urn: args[:new_urn])

    raise "Could not find one or both schools." if old_loc.nil? || new_loc.nil?

    if !new_loc.team_id.nil? && new_loc.team_id != old_loc.team_id
      raise "#{new_loc.urn} belongs to #{new_loc.team.name}. Could not complete transfer."
    end
    new_loc.update!(team: old_loc.team)

    Session.where(location_id: old_loc.id).update_all(location_id: new_loc.id)
    Patient.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
    ConsentForm.where(location_id: old_loc.id).update_all(
      location_id: new_loc.id
    )
    ConsentForm.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
    SchoolMove.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
    Patient
      .where(school_id: new_loc.id)
      .find_each do |patient|
        SchoolMoveLogEntry.create!(patient:, school: new_loc)
      end
  end
end
