# frozen_string_literal: true

describe "Import class lists" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User uploads a file" do
    given_an_hpv_programme_is_underway

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    then_i_should_see_the_import_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_a_malformed_csv
    then_i_should_see_an_error

    when_i_upload_a_file_with_invalid_headers
    then_i_should_the_errors_page_with_invalid_headers

    when_i_upload_a_file_with_invalid_fields
    then_i_should_see_the_imports_page

    when_i_wait_for_the_background_job_to_complete
    and_i_go_to_the_import_edit_page
    then_i_should_the_errors_page_with_invalid_fields
    and_i_go_back_to_the_upload_page

    when_i_upload_a_valid_file
    then_i_should_see_the_imports_page

    when_i_wait_for_the_background_job_to_complete
    and_i_go_to_the_import_edit_page
    then_i_should_see_the_patients

    when_i_click_on_upload_records
    then_i_should_see_the_upload
    and_i_should_see_the_patients

    when_i_click_on_the_imports_tab
    then_i_should_see_the_import

    when_i_visit_a_session_page_for_the_hpv_programme
    then_i_should_see_the_children_added_to_the_session
  end

  def given_an_hpv_programme_is_underway
    @team = create(:team, :with_one_nurse)
    create(:location, :secondary, name: "Waterloo Road", team: @team)
    @user = @team.users.first
    create(:programme, :hpv, teams: [@team])
  end

  def when_i_visit_a_session_page_for_the_hpv_programme
    sign_in @user
    visit "/dashboard"
    click_on "School sessions", match: :first
    click_on "Unscheduled"
    click_on "Waterloo Road"
  end

  def and_i_start_adding_children_to_the_session
    click_on "Import class list"
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Import class list")
  end

  def when_i_upload_a_valid_file
    attach_file("class_import[csv]", "spec/fixtures/class_import/valid.csv")
    click_on "Continue"
  end

  def then_i_should_see_the_patients
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("Jimmy Smith")
    expect(page).to have_content(/NHS number.*123.*456.*7890/)
    expect(page).to have_content("Date of birth 1 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
  end
  alias_method :and_i_should_see_the_patients, :then_i_should_see_the_patients

  def when_i_click_on_upload_records
    click_on "Upload records"
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Uploaded on")
    expect(page).to have_content("Uploaded byTest User")
    expect(page).to have_content("SessionWaterloo Road")
  end

  def when_i_click_on_the_imports_tab
    click_on "Programmes"
    click_on "HPV"
    click_on "Imports"
  end

  def then_i_should_see_the_import
    expect(page).to have_content("1 completed import")
  end

  def then_i_should_see_the_children_added_to_the_session
    expect(page).to have_content("4 children in this session")
  end

  def then_i_should_see_the_children
    expect(page).to have_content("4 children")
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("Full name Jimmy Smith")
    expect(page).to have_content(/NHS number.*123.*456.*7890/)
    expect(page).to have_content("Date of birth 1 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Continue"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_a_malformed_csv
    attach_file("class_import[csv]", "spec/fixtures/class_import/malformed.csv")
    click_on "Continue"
  end

  def when_i_upload_a_file_with_invalid_headers
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/invalid_headers.csv"
    )
    click_on "Continue"
  end

  def then_i_should_the_errors_page_with_invalid_headers
    expect(page).to have_content("The file is missing the following headers")
  end

  def when_i_upload_a_file_with_invalid_fields
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/invalid_fields.csv"
    )
    click_on "Continue"
  end

  def then_i_should_the_errors_page_with_invalid_fields
    expect(page).to have_content("Class list cannot be uploaded")
    expect(page).to have_content("Row 2")
  end

  def and_i_go_back_to_the_upload_page
    click_on "Back"
  end

  def then_i_should_see_the_imports_page
    expect(page).to have_content("Import processing started")
  end

  def when_i_wait_for_the_background_job_to_complete
    perform_enqueued_jobs
  end

  def and_i_go_to_the_import_edit_page
    click_link ClassImport.last.created_at.to_fs(:long), match: :first
  end
end
