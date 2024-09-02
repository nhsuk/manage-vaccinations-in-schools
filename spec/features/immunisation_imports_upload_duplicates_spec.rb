# frozen_string_literal: true

describe "Immunisation imports duplicates" do
  scenario "User reviews and selects between duplicate records" do
    given_i_am_signed_in
    and_an_hpv_campaign_is_underway
    and_an_existing_patient_record_exists

    when_i_go_to_the_reports_page
    and_i_click_on_the_upload_link
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_edit_page_with_duplicate_records

    when_i_review_the_duplicate_record
    then_i_should_see_the_duplicate_record

    # when_i_select_the_new_record
    # and_i_confirm_my_selection
    # then_i_should_see_a_success_message
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_an_hpv_campaign_is_underway
    @campaign =
      create(:campaign, :hpv_all_vaccines, academic_year: 2023, team: @team)
    @location = create(:location, :school, urn: "110158")
    @session = create(:session, campaign: @campaign, location: @location)
  end

  def and_an_existing_patient_record_exists
    @existing_patient =
      create(
        :patient,
        first_name: "Esmae",
        last_name: "O'Connell",
        nhs_number: "7420180008", # First row of valid_hpv.csv
        date_of_birth: Date.new(2014, 3, 29),
        gender_code: :female,
        address_postcode: "QG53 3OA",
        school: @location
      )
  end

  def when_i_go_to_the_reports_page
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Uploads"
  end

  def and_i_click_on_the_upload_link
    click_on "Upload new vaccination records"
  end

  def and_i_upload_a_file_with_duplicate_records
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_edit_page_with_duplicate_records
    expect(page).to have_content("1 duplicate record needs review")
  end

  def when_i_select_the_new_record
    choose "Use new record"
  end

  def and_i_confirm_my_selection
    click_on "Confirm"
  end

  def then_i_should_see_a_success_message
    expect(page).to have_content("Duplicate record reviewed successfully")
  end

  def when_i_review_the_duplicate_record
    click_on "Review Esmae O'Connell"
  end

  def then_i_should_see_the_duplicate_record
    expect(page).to have_content("This record needs reviewing")
  end
end
