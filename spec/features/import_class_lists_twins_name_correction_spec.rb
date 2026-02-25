# frozen_string_literal: true

describe "Class list imports twin name corrections" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User can re-upload corrected twin names without a hard stop" do
    given_an_hpv_programme_is_underway
    and_i_am_signed_in

    when_i_upload_the_twins_file("twins_with_typos.csv")
    then_the_import_should_complete_without_errors

    when_i_upload_the_twins_file("twins_with_corrections.csv")
    then_i_should_see_the_import_page_with_duplicate_records
  end

  def given_an_hpv_programme_is_underway
    programmes = [Programme.hpv]
    @team = create(:team, :with_generic_clinic, :with_one_nurse, programmes:)
    @location = create(:school, name: "Waterloo Road", team: @team)
    @user = @team.users.first
    create(
      :session,
      :unscheduled,
      team: @team,
      location: @location,
      programmes:
    )
  end

  def and_i_am_signed_in
    sign_in @user
  end

  def when_i_upload_the_twins_file(filename)
    visit "/dashboard"
    click_on "Schools", match: :first

    click_on "Waterloo Road"
    click_on "Import class lists"

    check "Year 8"
    check "Year 9"
    check "Year 10"
    check "Year 11"
    click_on "Continue"

    attach_file_fixture "class_import[csv]", "class_import/#{filename}"
    click_on "Continue"

    wait_for_import_to_complete(ClassImport)
  end

  def then_the_import_should_complete_without_errors
    expect(page).to have_content("Imported records")
    expect(page).not_to have_content(
      "Two or more possible patients match the patient first name, last name, date of birth or postcode."
    )
  end

  def then_i_should_see_the_import_page_with_duplicate_records
    expect(page).to have_content(
      "Close matches to existing records - needs review"
    )
    expect(page).to have_content("2 upload issues")
  end
end
