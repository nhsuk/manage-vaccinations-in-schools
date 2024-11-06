# frozen_string_literal: true

describe "Edit vaccination record" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "User edits the vaccination record" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_a_vaccination_record_exists

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_date
    then_i_should_see_the_date_time_form

    when_i_fill_in_an_invalid_date
    and_i_click_continue
    then_i_see_the_date_time_form_with_errors

    when_i_fill_in_an_invalid_time
    and_i_click_continue
    then_i_see_the_date_time_form_with_errors

    when_i_fill_in_a_valid_date_and_time
    and_i_click_continue
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_date_time

    when_i_click_on_change_batch
    and_i_choose_a_batch
    and_i_click_continue
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_batch
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse, ods_code: "R1L")
    sign_in @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    create(
      :organisation_programme,
      organisation: @organisation,
      programme: @programme
    )
    location = create(:location, :school)
    @session =
      create(
        :session,
        organisation: @organisation,
        programme: @programme,
        location:
      )
  end

  def and_a_vaccination_record_exists
    patient = create(:patient, given_name: "John", family_name: "Smith")

    vaccine = @programme.vaccines.first
    @original_batch = create(:batch, organisation: @organisation, vaccine:)
    @replacement_batch = create(:batch, organisation: @organisation, vaccine:)

    create(
      :vaccination_record,
      programme: @programme,
      patient_session: create(:patient_session, patient:, session: @session),
      batch: @original_batch
    )
  end

  def when_i_go_to_the_vaccination_records_page
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
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

  def when_i_click_on_edit_vaccination_record
    click_on "Edit vaccination record"
  end

  def then_i_see_the_edit_vaccination_record_page
    expect(page).to have_content("Edit vaccination record")
  end

  def when_i_click_on_change_date
    click_on "Change date"
  end

  def then_i_should_see_the_date_time_form
    expect(page).to have_content("Date")
    expect(page).to have_content("Time")
  end

  def when_i_fill_in_a_valid_date_and_time
    fill_in "Year", with: "2023"
    fill_in "Month", with: "9"
    fill_in "Day", with: "1"

    fill_in "Hour", with: "12"
    fill_in "Minute", with: "00"
  end

  def when_i_fill_in_an_invalid_date
    fill_in "Year", with: "3023"
    fill_in "Month", with: "19"
    fill_in "Day", with: "33"

    fill_in "Hour", with: "23"
    fill_in "Minute", with: "15"
  end

  def when_i_fill_in_an_invalid_time
    fill_in "Year", with: "2025"
    fill_in "Month", with: "5"
    fill_in "Day", with: "1"

    fill_in "Hour", with: "25"
    fill_in "Minute", with: "61"
  end

  def then_i_see_the_date_time_form_with_errors
    expect(page).to have_content("There is a problem")
  end

  def and_i_click_continue
    click_on "Continue"
  end

  def and_i_should_see_the_updated_date_time
    expect(page).to have_content("Date1 September 2023")
    expect(page).to have_content("Time12:00pm")
  end

  def when_i_click_on_change_batch
    click_on "Change batch"
  end

  def and_i_choose_a_batch
    choose @replacement_batch.name
  end

  def and_i_should_see_the_updated_batch
    expect(page).to have_content("Batch ID#{@replacement_batch.name}")
  end
end
