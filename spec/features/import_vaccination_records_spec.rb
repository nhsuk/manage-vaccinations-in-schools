# frozen_string_literal: true

describe "Immunisation imports" do
  around { |example| travel_to(Date.new(2025, 5, 20)) { example.run } }

  scenario "User uploads a file, views cohort and vaccination records" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_school_locations_exist

    when_i_go_to_the_vaccinations_page
    then_i_should_see_the_upload_link

    when_i_click_on_the_upload_link
    then_i_should_see_the_upload_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_an_invalid_file
    then_i_should_see_the_errors_page

    travel_to 1.minute.from_now # to ensure the created_at is different for the import jobs

    when_i_go_back_to_the_upload_page
    and_i_upload_a_valid_file
    then_i_should_see_the_upload
    and_i_should_see_the_vaccination_records

    when_i_click_on_a_vaccination_record
    then_i_should_see_the_vaccination_record

    when_i_click_on_cohorts
    then_i_should_see_no_children_in_the_cohorts

    when_i_click_on_vaccination_records
    then_i_should_see_the_vaccination_records
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse, ods_code: "R1L")
    sign_in @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    programme =
      create(:programme, :hpv_all_vaccines, organisations: [@organisation])
    location = create(:school)
    @session =
      create(:session, programme:, location:, organisation: @organisation)
  end

  def and_school_locations_exist
    create(:school, urn: "110158")
    create(:school, urn: "120026")
    create(:school, urn: "144012")
  end

  def when_i_go_to_the_vaccinations_page
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
  end

  def then_i_should_see_the_upload_link
    expect(page).to have_link("Import vaccination records")
  end

  def when_i_click_on_the_upload_link
    click_on "Import vaccination records"
  end

  def when_i_click_on_the_imports_tab
    click_on "Imports"
  end

  def and_i_choose_to_import_child_records
    click_on "Import records"
    choose "Vaccination records"
    click_on "Continue"
  end

  def then_i_should_see_the_upload_page
    expect(page).to have_content("Import vaccination records")
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
      "spec/fixtures/immunisation_import/invalid_rows.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_errors_page
    expect(page).to have_content(
      "How to format your CSV for vaccination records"
    )
    expect(page).to have_content("Row 2")
    expect(page).to have_content("VACCINATED:")

    expect(page).to have_content("Row 2")
    expect(page).to have_content("BATCH_EXPIRY_DATE:")
    expect(page).to have_content("ANATOMICAL_SITE:")
    expect(page).to have_content("VACCINE_GIVEN:")
  end

  def when_i_go_back_to_the_upload_page
    click_on "Back"
    click_on "Import records"
    choose "Vaccination records"
    click_on "Continue"
  end

  def and_i_upload_a_valid_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_success_heading
    expect(page).to have_content("8 new vaccination records")
  end

  def then_i_should_see_the_vaccination_records
    expect(page).to have_content(
      "Full nameNHS numberDate of birthVaccination date"
    )
    expect(page).to have_content("Full name PICKLE, Chyna")
    expect(page).to have_content(/NHS number.*742.*018.*0008/)
    expect(page).to have_content("Date of birth 12 September 2010")
    expect(page).to have_content("Vaccination date 14 May 2024")
  end

  alias_method :and_i_should_see_the_vaccination_records,
               :then_i_should_see_the_vaccination_records

  def when_i_go_back
    click_on "Back to check and confirm upload"
  end

  def and_i_click_on_upload_records
    click_on "Upload records"
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def when_i_click_on_a_vaccination_record
    click_on "PICKLE, Chyna"
  end

  def when_i_click_on_cohorts
    click_on "HPV"
    click_on "Cohorts"
  end

  def then_i_should_see_no_children_in_the_cohorts
    expect(page).to have_content("Year 8\nNo children")
    expect(page).to have_content("Year 9\nNo children")
    expect(page).to have_content("Year 10\nNo children")
    expect(page).to have_content("Year 11\nNo children")
  end

  def when_i_click_on_vaccination_records
    click_on "HPV"
    click_on "Vaccinations", match: :first
  end

  def then_i_should_see_the_vaccination_record
    expect(page).to have_content("PICKLE, Chyna")
    expect(page).to have_content("Child")
    expect(page).to have_content("Full namePICKLE, Chyna")
    expect(page).to have_content("Vaccination details")
    expect(page).to have_content("OutcomeVaccinated")
  end

  def when_i_click_on_the_vaccinations_tab
    click_on "Vaccinations", match: :first
  end

  alias_method :and_i_click_on_the_upload_link, :when_i_click_on_the_upload_link
end
