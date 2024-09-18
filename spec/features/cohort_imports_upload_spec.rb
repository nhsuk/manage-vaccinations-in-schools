# frozen_string_literal: true

describe "Cohort imports" do
  scenario "User uploads a file" do
    given_the_app_is_setup
    and_an_hpv_programme_is_underway

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    then_i_should_see_the_upload_cohort_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_a_malformed_csv
    then_i_should_see_an_error

    when_i_upload_a_file_with_invalid_headers
    then_i_should_the_errors_page_with_invalid_headers

    when_i_upload_a_file_with_invalid_fields
    then_i_should_the_errors_page_with_invalid_fields
    and_i_go_back_to_the_upload_page

    when_i_upload_a_valid_file
    and_i_should_see_the_patients

    when_i_click_on_upload_records
    then_i_should_see_the_upload
    and_i_should_see_the_patients

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    then_i_should_see_the_upload_cohort_page

    when_i_upload_a_valid_file
    then_i_should_see_the_duplicates_page
  end

  def given_the_app_is_setup
    @team = create(:team, :with_one_nurse)
    create(:location, :school, urn: "123456")
    @user = @team.users.first
  end

  def and_an_hpv_programme_is_underway
    create(:programme, :hpv, academic_year: 2023, team: @team)
  end

  def when_i_visit_the_cohort_page_for_the_hpv_programme
    sign_in @user
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
  end

  def and_i_start_adding_children_to_the_cohort
    click_on "Import child records"
  end

  def then_i_should_see_the_upload_cohort_page
    expect(page).to have_content("Upload cohort records")
  end

  def when_i_upload_a_valid_file
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/valid_cohort.csv"
    )
    click_on "Continue"
  end

  def and_i_should_see_the_patients
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("Jimmy Smith")
    expect(page).to have_content(/NHS number.*123.*456.*7890/)
    expect(page).to have_content("Date of birth 1 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
  end

  def when_i_click_on_upload_records
    click_on "Upload records"
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Uploaded on")
    expect(page).to have_content("Uploaded byTest User")
    expect(page).to have_content("ProgrammeHPV")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Continue"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_a_malformed_csv
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/malformed.csv"
    )
    click_on "Continue"
  end

  def when_i_upload_a_file_with_invalid_headers
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/invalid_headers.csv"
    )
    click_on "Continue"
  end

  def then_i_should_the_errors_page_with_invalid_headers
    expect(page).to have_content("The file is missing the following headers")
  end

  def when_i_upload_a_file_with_invalid_fields
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/invalid_fields.csv"
    )
    click_on "Continue"
  end

  def then_i_should_the_errors_page_with_invalid_fields
    expect(page).to have_content("Cohort records cannot be uploaded")
    expect(page).to have_content("Row 2")
  end

  def and_i_go_back_to_the_upload_page
    click_on "Back"
  end

  def then_i_should_see_the_duplicates_page
    expect(page).to have_content(
      "All records in this CSV file have been uploaded."
    )
  end
end
