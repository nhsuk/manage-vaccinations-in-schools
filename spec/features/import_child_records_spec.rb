# frozen_string_literal: true

describe "Import child records" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User uploads a file" do
    given_the_app_is_setup

    when_i_visit_the_import_page
    and_i_choose_to_import_child_records
    then_i_should_see_the_import_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_a_malformed_csv
    then_i_should_see_an_error

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

    when_i_click_on_a_patient
    then_i_should_see_the_patient_details

    when_i_visit_the_hpv_programme_page
    then_i_should_see_the_cohorts_for_hpv

    when_i_click_on_the_cohort_for_hpv
    then_i_should_see_the_children_for_hpv

    when_i_search_for_a_child
    then_i_should_see_only_the_child

    when_i_visit_the_doubles_programme_page
    then_i_should_see_the_cohorts_for_doubles

    when_i_click_on_the_cohort_for_doubles
    then_i_should_see_the_children_for_doubles

    when_i_visit_the_hpv_programme_page
    and_i_import_child_records_from_children_tab
    then_i_should_see_the_import_page

    travel 1.minute # to ensure the created_at is different for the import jobs

    when_i_upload_a_valid_file_with_changes
    and_i_go_to_the_import_page
    then_i_should_see_import_issues_with_the_count
  end

  context "when PDS lookup during import and import_review_screenis enabled" do
    scenario "User uploads a file" do
      given_the_app_is_setup
      and_pds_lookup_during_import_is_enabled
      and_import_review_screen_is_enabled

      when_i_visit_the_import_page
      and_i_choose_to_import_child_records
      then_i_should_see_the_import_page

      when_i_continue_without_uploading_a_file
      then_i_should_see_an_error

      when_i_upload_a_malformed_csv
      then_i_should_see_an_error

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

      when_i_click_on_a_patient
      then_i_should_see_the_patient_details

      when_i_visit_the_hpv_programme_page
      then_i_should_see_the_cohorts_for_hpv

      when_i_click_on_the_cohort_for_hpv
      then_i_should_see_the_children_for_hpv

      when_i_search_for_a_child
      then_i_should_see_only_the_child

      when_i_visit_the_doubles_programme_page
      then_i_should_see_the_cohorts_for_doubles

      when_i_click_on_the_cohort_for_doubles
      then_i_should_see_the_children_for_doubles

      when_i_visit_the_hpv_programme_page
      and_i_import_child_records_from_children_tab
      then_i_should_see_the_import_page

      travel 1.minute # to ensure the created_at is different for the import jobs

      when_i_upload_a_valid_file_with_changes
      and_i_go_to_the_import_page
      then_i_should_see_import_issues_with_the_count
    end
  end

  def given_the_app_is_setup
    programmes = [
      CachedProgramme.hpv,
      CachedProgramme.menacwy,
      CachedProgramme.td_ipv
    ]

    @team = create(:team, :with_generic_clinic, :with_one_nurse, programmes:)

    create(:school, urn: "123456", team: @team)
    @user = @team.users.first

    TeamSessionsFactory.call(@team, academic_year: AcademicYear.current)
  end

  def and_pds_lookup_during_import_is_enabled
    Flipper.enable(:import_search_pds)

    stub_pds_search_to_return_a_patient(
      "9990000026",
      "family" => "Smith",
      "given" => "Jimmy",
      "birthdate" => "eq2010-01-02",
      "address-postalcode" => "SW1A 1AA"
    )

    stub_pds_search_to_return_a_patient(
      "9999075320",
      "family" => "Clarke",
      "given" => "Jennifer",
      "birthdate" => "eq2010-01-01",
      "address-postalcode" => "SW1A 1AA"
    )

    stub_pds_search_to_return_a_patient(
      "9999075320",
      "family" => "Clarke",
      "given" => "Jennifer",
      "birthdate" => "eq2010-01-01",
      "address-postalcode" => "SW1A 1AB"
    )

    stub_pds_search_to_return_a_patient(
      "9435764479",
      "family" => "Doe",
      "given" => "Mark",
      "birthdate" => "eq2010-01-03",
      "address-postalcode" => "SW1A 1AA"
    )
  end

  def and_import_review_screen_is_enabled
    Flipper.enable(:import_review_screen)
  end

  def when_i_visit_the_import_page
    sign_in @user
    visit "/dashboard"
    click_on "Import", match: :first
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
    wait_for_import_to_complete(CohortImport)
  end

  def and_i_should_see_the_patients
    expect(page).to have_content(
      "Name and NHS numberPostcodeSchoolDate of birth"
    )
    expect(page).to have_content("SMITH, Jimmy")
    expect(page).to have_content(/NHS number.*999.*000.*0018/)
    expect(page).to have_content("Date of birth 1 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
  end

  def when_i_click_on_a_patient
    click_on "DOE, Mark"
  end

  def then_i_should_see_the_patient_details
    expect(page).to have_content("Child’s details")
    expect(page).to have_content("DOE, Mark")
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def when_i_visit_the_hpv_programme_page
    click_on "Programmes", match: :first
    click_on "HPV"
  end

  def when_i_visit_the_doubles_programme_page
    click_on "Programmes", match: :first
    click_on "MenACWY"
  end

  def then_i_should_see_the_cohorts_for_hpv
    expect(page).to have_content("Children\n3")
    expect(page).to have_content("Year 8\n2 children")
    expect(page).to have_content("Year 9\n1 child")
    expect(page).to have_content("Year 10\nNo children")
    expect(page).to have_content("Year 11\nNo children")
  end

  def when_i_click_on_the_cohort_for_hpv
    click_on "Year 8"
  end

  def then_i_should_see_the_children_for_hpv
    expect(page).to have_content("2 children")
    expect(page).to have_content("DOE, Mark")
    expect(page).to have_content("SMITH, Jimmy")
  end

  def when_i_search_for_a_child
    fill_in "Search", with: "DOE, Mark"
    click_on "Search"
  end

  def then_i_should_see_only_the_child
    expect(page).to have_content("1 child")
    expect(page).to have_content("DOE, Mark")
  end

  def then_i_should_see_the_cohorts_for_doubles
    expect(page).to have_content("Children\n1")
    expect(page).not_to have_content("Year 8")
    expect(page).to have_content("Year 9\n1 child")
    expect(page).to have_content("Year 10\nNo children")
    expect(page).to have_content("Year 11\nNo children")
  end

  def when_i_click_on_the_cohort_for_doubles
    within all(".nhsuk-card")[0] do
      click_on "Children"
    end
  end

  def then_i_should_see_the_children_for_doubles
    expect(page).not_to have_content("Year 8")
    expect(page).to have_content("1 child")
    expect(page).to have_content("CLARKE, Jennifer")
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

  def when_i_upload_a_file_with_invalid_fields
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/invalid_fields.csv"
    )
    click_on "Continue"
  end

  def then_i_should_the_errors_page_with_invalid_fields
    expect(page).to have_content(
      "How to format your Mavis CSV file for child records"
    )
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
    perform_enqueued_jobs(only: ProcessImportJob)
    perform_enqueued_jobs(only: PDSCascadingSearchJob)
    perform_enqueued_jobs(only: ProcessPatientChangesetJob)
    perform_enqueued_jobs(only: CommitImportJob)
  end

  def then_i_should_see_the_holding_page
    expect(page).to have_css(".nhsuk-tag", text: "Processing")
  end

  def and_i_refresh_the_page
    visit current_path
  end

  def when_i_go_to_the_import_page
    click_on_most_recent_import(CohortImport)
  end

  def and_i_import_child_records_from_children_tab
    within(".app-secondary-navigation") { click_on "Children" }

    click_on "Import child records"
    click_on "Continue"
  end

  def when_i_upload_a_valid_file_with_changes
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/valid_with_changes.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete(CohortImport)
  end

  def and_i_go_to_the_import_page
    click_on "Import", match: :first
  end

  def then_i_should_see_import_issues_with_the_count
    expect(page).to have_link("Import issues")
    expect(page).to have_selector(".app-count", text: "(1)").twice
  end
end
