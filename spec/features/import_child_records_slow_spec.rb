# frozen_string_literal: true

describe "Import child records" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User uploads a large file" do
    given_the_app_is_setup
    and_an_hpv_programme_is_underway

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    then_i_should_see_the_import_page

    when_i_upload_a_valid_file
    then_i_should_see_the_imports_page_with_the_processing_flash

    when_i_wait_for_the_background_job_to_complete
    when_i_go_to_the_import_page
    then_i_should_see_the_upload
    and_i_should_see_the_patients
    and_i_should_see_the_pagination_buttons

    when_i_click_on_next_page
    then_i_should_see_the_upload
    and_i_should_see_the_patients_for_page_two
  end

  def given_the_app_is_setup
    @organisation = create(:organisation, :with_one_nurse)
    create(:school, urn: "141939")
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

  def then_i_should_see_the_import_page
    expect(page).to have_content("Import child records")
  end

  def when_i_upload_a_valid_file
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/valid_1000_rows.csv"
    )
    click_on "Continue"
  end

  def and_i_should_see_the_patients
    expect(page).to have_content("1000 children")
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("MAYER, Roxanna")
  end

  def and_i_should_see_the_patients_for_page_two
    expect(page).to have_content("1000 children")
    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")
    expect(page).to have_content("CHRISTIANSEN, Elijah")
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def then_i_should_see_the_imports_page_with_the_processing_flash
    expect(page).to have_content("Import processing started")
  end

  def when_i_wait_for_the_background_job_to_complete
    perform_enqueued_jobs
  end

  def when_i_go_to_the_import_page
    click_link CohortImport.last.created_at.to_fs(:long), match: :first
  end

  def and_i_should_see_the_pagination_buttons
    expect(page).to have_content("12345⋯50")
    expect(page).to have_content("Next page")
  end

  def when_i_click_on_next_page
    click_on "Next page"
  end
end
