# frozen_string_literal: true

describe "Import child records" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User uploads a file" do
    given_the_app_is_setup
    and_an_hpv_programme_is_underway

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    then_i_should_see_the_import_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_a_malformed_csv
    then_i_should_see_an_error

    when_i_upload_a_file_with_invalid_headers
    then_i_should_the_errors_page_with_invalid_headers

    when_i_upload_a_file_with_invalid_fields
    then_i_should_see_the_imports_page_with_the_processing_flash

    when_i_go_to_the_import_page
    then_i_should_see_the_holding_page

    when_i_wait_for_the_background_job_to_complete
    and_i_refresh_the_page
    then_i_should_the_errors_page_with_invalid_fields

    when_it_is_a_litte_bit_later
    and_i_go_back_to_the_upload_page
    and_i_upload_a_valid_file
    then_i_should_see_the_upload
    and_i_should_see_the_patients

    when_i_visit_the_cohort_page_for_the_hpv_programme
    then_i_should_see_the_cohorts

    when_i_click_on_the_cohort
    then_i_should_see_the_children

    when_i_click_on_the_imports_tab
    and_i_choose_to_import_child_records
    then_i_should_see_the_import_page

    travel_to 1.minute.from_now # to ensure the created_at is different for the import jobs

    when_i_upload_a_valid_file_with_changes
    and_i_go_to_the_imports_page
    then_i_should_see_import_issues_with_the_count
  end

  def given_the_app_is_setup
    @organisation = create(:organisation, :with_one_nurse)
    create(:school, urn: "123456", organisation: @organisation)
    @user = @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    create(:organisation_programme, organisation: @organisation, programme:)
  end

  def when_i_visit_the_cohort_page_for_the_hpv_programme
    sign_in @user
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
  end

  def and_i_start_adding_children_to_the_cohort
    click_on "Import child records"
  end

  def and_i_choose_to_import_child_records
    click_on "Import records"
    choose "Child records"
    click_on "Continue"
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Import child records")
  end

  def and_i_upload_a_valid_file
    attach_file("cohort_import[csv]", "spec/fixtures/cohort_import/valid.csv")
    click_on "Continue"
  end

  def then_i_should_see_the_patients
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("SMITH, Jimmy")
    expect(page).to have_content(/NHS number.*123.*456.*7890/)
    expect(page).to have_content("Date of birth 1 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
  end
  alias_method :and_i_should_see_the_patients, :then_i_should_see_the_patients

  def when_i_click_on_upload_records
    click_on "Upload records"
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def when_i_click_on_the_imports_tab
    click_on "HPV"
    click_on "Imports"
  end

  def then_i_should_see_the_import
    expect(page).to have_content("1 completed import")
  end

  def then_i_should_see_the_cohorts
    expect(page).to have_content("Year 8\n2 children")
    expect(page).to have_content("Year 9\n1 child")
    expect(page).to have_content("Year 10\nNo children")
    expect(page).to have_content("Year 11\nNo children")
  end

  def when_i_click_on_the_cohort
    click_on "Year 8"
  end

  def then_i_should_see_the_children
    expect(page).to have_content("2 children")
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("Full name SMITH, Jimmy")
    expect(page).to have_content(/NHS number.*123.*456.*7891/)
    expect(page).to have_content("Date of birth 2 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
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
    expect(page).to have_content("How to format your CSV for child records")
    expect(page).to have_content("Row 2")
  end

  def when_it_is_a_litte_bit_later
    travel_to(1.minute.from_now) # so the imports are in a deterministic order
  end

  def and_i_go_back_to_the_upload_page
    click_on "Back"
    click_on "Import records"
    choose "Child records"
    click_on "Continue"
  end

  def then_i_should_see_the_imports_page_with_the_processing_flash
    expect(page).to have_content("Import processing started")
  end

  def when_i_wait_for_the_background_job_to_complete
    perform_enqueued_jobs
  end

  def then_i_should_see_the_holding_page
    expect(page).to have_css(".nhsuk-tag", text: "Processing")
  end

  def and_i_refresh_the_page
    visit current_path
  end

  def when_i_go_to_the_import_page
    click_link CohortImport.last.created_at.to_fs(:long), match: :first
  end

  def when_i_upload_a_valid_file_with_changes
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/valid_with_changes.csv"
    )
    click_on "Continue"
  end

  def and_i_go_to_the_imports_page
    click_on "Imports"
  end

  def then_i_should_see_import_issues_with_the_count
    expect(page).to have_link("Import issues")
    expect(page).to have_selector(".app-count", text: "( 1 )")
  end
end
