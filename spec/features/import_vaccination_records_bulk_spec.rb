# frozen_string_literal: true

describe("Immunisation imports") do
  around { |example| travel_to(Date.new(2025, 12, 20)) { example.run } }

  scenario "User uploads a mixed flu and HPV file, views cohort and vaccination records" do
    given_mavis_logins_are_configured
    given_i_am_signed_in_as_a_bulk_upload_user

    when_i_go_to_the_import_page
    then_i_should_see_the_upload_link

    when_i_click_on_the_upload_link
    then_i_should_see_the_upload_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_an_invalid_file
    then_i_should_see_the_errors_page

    travel_to 1.minute.from_now # to ensure the created_at is different for the import jobs

    when_i_go_back_to_the_upload_page
    and_i_upload_a_valid_mixed_file
    then_i_should_see_the_upload
    and_i_should_see_the_vaccination_records
    and_the_patients_should_now_be_associated_with_the_team

    # TODO: make sure this is added after patients are visible in the "Children" page
    # when_i_click_on_a_vaccination_record
    # then_i_should_see_the_vaccination_record
  end

  def given_mavis_logins_are_configured
    programmes = [Programme.flu, Programme.hpv]
    @team =
      create(
        :team,
        :with_one_nurse,
        ods_code: "R1L",
        programmes: programmes,
        type: "upload_only"
      )
    create(:school, team: @team, urn: 100_000)
  end

  def given_i_am_signed_in_as_a_bulk_upload_user
    sign_in @team.users.first
  end

  def and_school_locations_exist
    create(:school, urn: "110158")
    create(:school, urn: "120026")
    create(:school, urn: "144012")
  end

  def when_i_go_to_the_import_page
    visit "/dashboard"

    click_on "Import", match: :first
  end

  def then_i_should_see_the_upload_link
    expect(page).to have_button("Upload records")
  end

  def when_i_click_on_the_upload_link
    click_on "Upload records"
  end

  def when_i_click_on_the_imports_tab
    click_on "Imports"
  end

  def and_i_choose_to_import_child_records
    click_on "Upload records"
    choose "Vaccination records"
    click_on "Continue"
  end

  def then_i_should_see_the_upload_page
    expect(page).to have_content("Upload vaccination records")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Continue"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_an_invalid_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import_bulk/invalid_rows.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete(ImmunisationImport)
  end

  def then_i_should_see_the_errors_page
    expect(page).to have_content(
      "How to format your CSV file for vaccination records"
    )
    expect(page).to have_content("Row 2")
    expect(page).to have_content("ANATOMICAL_SITE:")
    expect(page).to have_content("SCHOOL_URN:")

    expect(page).to have_content("Row 3")
    expect(page).to have_content("BATCH_EXPIRY_DATE:")
  end

  def when_i_go_back_to_the_upload_page
    click_on "Back"
    click_on "Upload records"
  end

  def and_i_upload_a_valid_mixed_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import_bulk/valid_mixed_flu_hpv.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete(ImmunisationImport)
  end

  def and_i_should_see_the_vaccination_records
    expect(page).to have_content(
      "Full nameNHS numberDate of birthVaccination date"
    )
    expect(page).to have_content("Full name POTTER, Harry")
    expect(page).to have_content(/NHS number.*944.*930.*8357/)
    expect(page).to have_content("Date of birth 1 January 2001")
    expect(page).to have_content("Vaccination date 9 November 2025")
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Uploaded byUSER, Test")
  end

  def and_the_patients_should_now_be_associated_with_the_team
    Patient.all.find_each { |patient| expect(patient.teams).to include(@team) }
  end

  def when_i_click_on_a_vaccination_record
    find(".nhsuk-details__summary", text: "2 imported records").click
    click_on "POTTER, Harry"
  end

  def then_i_should_see_the_vaccination_record
    expect(page).to have_content("POTTER, Harry")
    expect(page).to have_content("Child")
    expect(page).to have_content("Full namePOTTER, Harry")
    expect(page).to have_content("Vaccination details")
    expect(page).to have_content("OutcomeVaccinated")
  end
end
