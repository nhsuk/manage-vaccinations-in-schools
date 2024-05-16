require "rails_helper"

RSpec.describe "Pilot - upload cohort" do
  scenario "User uploads a cohort list" do
    given_the_app_is_setup
    when_i_visit_the_pilot_dashboard
    then_i_should_see_the_manage_pilot_page

    when_i_click_the_upload_cohort_link
    then_i_should_see_the_upload_cohort_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_a_malformed_csv
    then_i_should_see_an_error

    when_i_upload_a_cohort_file_with_invalid_headers
    then_i_should_the_errors_page_with_invalid_headers
    and_i_should_be_able_to_go_back_to_the_upload_page

    when_i_upload_a_cohort_file_with_invalid_fields
    then_i_should_the_errors_page_with_invalid_fields
    and_i_should_be_able_to_go_to_the_upload_page

    when_i_upload_the_cohort_file
    then_i_should_see_the_success_page
  end

  def given_the_app_is_setup
    @team = create(:team, :with_one_nurse)
    create(:location, team: @team, id: 1)
    @user = @team.users.first
  end

  def when_i_visit_the_pilot_dashboard
    sign_in @user
    visit "/pilot"
  end

  def then_i_should_see_the_manage_pilot_page
    expect(page).to have_content("Manage pilot")
  end

  def when_i_click_the_upload_cohort_link
    click_on "Upload the cohort list"
  end

  def then_i_should_see_the_upload_cohort_page
    expect(page).to have_content("Upload the cohort list")
  end

  def when_i_upload_the_cohort_file
    attach_file(
      "cohort_list[csv]",
      "spec/fixtures/cohort_list/valid_cohort.csv"
    )
    click_on "Upload the cohort list"
  end

  def then_i_should_see_the_success_page
    expect(page).to have_content("Cohort data uploaded")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Upload the cohort list"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_a_malformed_csv
    attach_file("cohort_list[csv]", "spec/fixtures/cohort_list/malformed.csv")
    click_on "Upload the cohort list"
  end

  def when_i_upload_a_cohort_file_with_invalid_headers
    attach_file(
      "cohort_list[csv]",
      "spec/fixtures/cohort_list/invalid_headers.csv"
    )
    click_on "Upload the cohort list"
  end

  def then_i_should_the_errors_page_with_invalid_headers
    expect(page).to have_content("The cohort list could not be added")
    expect(page).to have_content("CSV")
  end

  def and_i_should_be_able_to_go_back_to_the_upload_page
    click_on "Back to cohort upload page"
  end

  def when_i_upload_a_cohort_file_with_invalid_fields
    attach_file(
      "cohort_list[csv]",
      "spec/fixtures/cohort_list/invalid_fields.csv"
    )
    click_on "Upload the cohort list"
  end

  def then_i_should_the_errors_page_with_invalid_fields
    expect(page).to have_content("The cohort list could not be added")
    expect(page).to have_content("Row 2")
  end

  def and_i_should_be_able_to_go_to_the_upload_page
    click_on "Upload a new cohort list"
  end
end
