# frozen_string_literal: true

describe "Edit vaccination record" do
  scenario "User edits the date/time" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_a_vaccination_record_exists

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
    then_i_should_see_the_vaccination_record

    when_i_click_on_the_change_link
    then_i_should_see_the_date_time_form

    when_i_fill_in_the_date
    and_i_fill_in_the_time
    and_i_click_continue
    then_i_should_see_the_vaccination_record
    and_i_should_see_the_updated_date_time
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    create(:team_programme, team: @team, programme: @programme)
    location = create(:location, :school)
    @session = create(:session, team: @team, programme: @programme, location:)
  end

  def and_a_vaccination_record_exists
    patient = create(:patient, given_name: "John", family_name: "Smith")

    create(
      :vaccination_record,
      programme: @programme,
      patient_session: create(:patient_session, patient:, session: @session)
    )
  end

  def when_i_go_to_the_vaccination_records_page
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations"
  end

  def then_i_should_see_the_vaccination_records
    expect(page).to have_content("1 vaccination record")
    expect(page).to have_content("John Smith")
  end

  def when_i_click_on_the_vaccination_record
    click_on "John Smith"
  end

  def then_i_should_see_the_vaccination_record
    expect(page).to have_content("Full nameJohn Smith")
  end

  def when_i_click_on_the_change_link
    click_on "Change"
  end

  def then_i_should_see_the_date_time_form
    expect(page).to have_content("Date")
    expect(page).to have_content("Time")
  end

  def when_i_fill_in_the_date
    fill_in "Year", with: "2023"
    fill_in "Month", with: "9"
    fill_in "Day", with: "1"
  end

  def and_i_fill_in_the_time
    fill_in "Hour", with: "12"
    fill_in "Minute", with: "00"
  end

  def and_i_click_continue
    click_on "Continue"
  end

  def and_i_should_see_the_updated_date_time
    expect(page).to have_content("Vaccination date1 September 2023 at 12:00pm")
  end
end
