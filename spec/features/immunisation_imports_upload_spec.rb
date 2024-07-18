# frozen_string_literal: true

require "rails_helper"

describe "Immunisation imports" do
  scenario "User uploads a file" do
    given_i_am_signed_in
    and_an_hpv_campaign_is_underway

    when_i_go_to_the_reports_page
    then_i_should_see_the_upload_link

    when_i_click_on_the_upload_link
    then_i_should_see_the_upload_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_an_invalid_file
    then_i_should_see_the_errors_page
    and_i_go_back_to_the_upload_page

    when_i_upload_a_valid_file
    then_i_should_see_the_success_page
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_an_hpv_campaign_is_underway
    campaign = create(:campaign, :hpv, team: @team)
    location = create(:location)
    @session = create(:session, campaign:, location:)
  end

  def when_i_go_to_the_reports_page
    visit "/dashboard"

    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Uploaded reports"
  end

  def then_i_should_see_the_upload_link
    expect(page).to have_link("Upload a new vaccination report")
  end

  def when_i_click_on_the_upload_link
    click_on "Upload a new vaccination report"
  end

  def then_i_should_see_the_upload_page
    expect(page).to have_content("Upload vaccination events")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Upload vaccination events"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_an_invalid_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/invalid_rows.csv"
    )
    click_on "Upload vaccination events"
  end

  def then_i_should_see_the_errors_page
    expect(page).to have_content("The vaccination events could not be added")
    expect(page).to have_content("Row 2")
  end

  def and_i_go_back_to_the_upload_page
    click_on "Upload a new vaccination report"
  end

  def when_i_upload_a_valid_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/nivs.csv"
    )
    click_on "Upload vaccination events"
  end

  def then_i_should_see_the_success_page
    expect(page).to have_content("Vaccination events uploaded")
  end
end
