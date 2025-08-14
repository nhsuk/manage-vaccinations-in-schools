# frozen_string_literal: true

describe "Edit session dates" do
  around { |example| travel_to(Time.zone.local(2024, 2, 18)) { example.run } }

  scenario "User can modify session dates without immediate saving" do
    given_i_have_a_session_with_existing_dates
    when_i_visit_the_session_edit_page
    then_i_see_the_existing_session_dates

    when_i_click_change_session_dates
    then_i_see_the_session_dates_page_with_existing_dates

    when_i_modify_the_first_date
    and_i_click_back
    then_i_should_be_back_on_session_edit_page
    and_the_original_dates_should_be_unchanged

    when_i_click_change_session_dates_again
    then_i_see_the_session_dates_page_with_original_dates

    when_i_modify_the_first_date_to_a_different_value
    and_i_click_continue
    then_i_should_be_back_on_session_edit_page
    and_the_dates_should_be_updated
  end

  scenario "User can add new session dates" do
    given_i_have_a_session_without_dates
    when_i_visit_the_session_edit_page
    then_i_see_add_session_dates_link

    when_i_click_add_session_dates
    then_i_see_the_session_dates_page_with_empty_form

    when_i_add_a_new_date
    and_i_click_add_another_date
    when_i_add_a_second_date
    and_i_click_continue
    then_i_should_be_back_on_session_edit_page
    and_i_should_see_both_new_dates
  end

  scenario "User gets validation error for invalid date" do
    given_i_have_a_session_without_dates
    when_i_visit_the_session_edit_page
    and_i_click_add_session_dates

    when_i_add_an_invalid_date
    and_i_click_continue
    then_i_should_see_invalid_date_error
  end

  scenario "User sees read-only display for session dates with attendances" do
    given_i_have_a_session_with_dates_and_attendances
    when_i_visit_the_session_edit_page
    then_i_see_the_existing_session_dates

    when_i_click_change_session_dates
    then_i_see_the_session_dates_page_with_attendance_restrictions
  end

  scenario "User can delete session dates" do
    given_i_have_a_session_with_existing_dates
    when_i_visit_the_session_edit_page
    then_i_see_the_existing_session_dates

    when_i_click_change_session_dates
    then_i_see_the_session_dates_page_with_existing_dates

    when_i_delete_the_first_date
    and_i_delete_the_new_first_date_too
    then_i_should_only_see_the_third_date

    and_i_click_continue
    then_i_should_be_back_on_session_edit_page
    and_only_the_third_date_should_remain
  end

  scenario "User can delete a newly added session date in the same session" do
    given_i_have_a_session_with_existing_dates
    when_i_visit_the_session_edit_page
    then_i_see_the_existing_session_dates

    when_i_click_change_session_dates
    then_i_see_the_session_dates_page_with_existing_dates

    and_i_click_add_another_date
    when_i_add_a_fourth_date
    then_i_should_see_four_dates

    when_i_delete_the_newly_added_fourth_date
    then_i_should_see_original_three_dates_only

    and_i_click_continue
    then_i_should_be_back_on_session_edit_page
    and_the_original_dates_should_be_unchanged
  end

  scenario "User cannot delete the last remaining session date" do
    given_i_have_a_session_with_one_date
    when_i_visit_the_session_edit_page
    then_i_see_the_single_session_date

    when_i_click_change_session_dates
    then_i_see_the_session_dates_page_with_one_date

    when_i_try_to_delete_the_only_date
    then_i_should_see_cannot_delete_last_date_error
    and_the_date_should_still_be_visible
  end

  def given_i_have_a_session_with_existing_dates
    @team = create(:team, :with_one_nurse)
    @session = create(:session, :unscheduled, team: @team)
    @original_date1 = Date.new(2024, 3, 15)
    @original_date2 = Date.new(2024, 3, 16)
    @original_date3 = Date.new(2024, 3, 17)
    @session.session_dates.create!(value: @original_date1)
    @session.session_dates.create!(value: @original_date2)
    @session.session_dates.create!(value: @original_date3)

    sign_in @team.users.first
  end

  def given_i_have_a_session_without_dates
    @team = create(:team, :with_one_nurse)
    @session = create(:session, :unscheduled, team: @team)

    sign_in @team.users.first
  end

  def given_i_have_a_session_with_one_date
    @team = create(:team, :with_one_nurse)
    @session = create(:session, :unscheduled, team: @team)
    @single_date = Date.new(2024, 3, 15)
    @session.session_dates.create!(value: @single_date)

    sign_in @team.users.first
  end

  def when_i_visit_the_session_edit_page
    visit edit_session_path(@session)
  end

  def then_i_see_the_existing_session_dates
    expect(page).to have_content("15 March 2024")
    expect(page).to have_content("16 March 2024")
    expect(page).to have_content("17 March 2024")
  end

  def then_i_see_add_session_dates_link
    expect(page).to have_link("Add session dates")
  end

  def when_i_click_change_session_dates
    click_link "Change session dates"
  end

  def when_i_click_change_session_dates_again
    when_i_click_change_session_dates
  end

  def when_i_click_add_session_dates
    click_link "Add session dates"
  end

  alias_method :and_i_click_add_session_dates, :when_i_click_add_session_dates

  def then_i_see_the_session_dates_page_with_existing_dates
    expect(page).to have_content("When will sessions be held?")

    # Check that existing dates are populated
    within page.all(".app-add-another__list-item")[0] do
      expect(page).to have_field("Day", with: "15")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end

    within page.all(".app-add-another__list-item")[1] do
      expect(page).to have_field("Day", with: "16")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end

    within page.all(".app-add-another__list-item")[2] do
      expect(page).to have_field("Day", with: "17")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end
  end

  def then_i_see_the_session_dates_page_with_original_dates
    then_i_see_the_session_dates_page_with_existing_dates
  end

  def then_i_see_the_session_dates_page_with_empty_form
    expect(page).to have_content("When will sessions be held?")
    # Check that there are empty form fields (they might have nil values)
    expect(page).to have_field("Day")
    expect(page).to have_field("Month")
    expect(page).to have_field("Year")
  end

  def when_i_modify_the_first_date
    within page.all(".app-add-another__list-item")[0] do
      fill_in "Day", with: "20"
    end
  end

  def when_i_modify_the_first_date_to_a_different_value
    within page.all(".app-add-another__list-item")[0] do
      fill_in "Day", with: "25"
    end
  end

  def when_i_add_a_new_date
    fill_in "Day", with: "15"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"
  end

  def when_i_add_a_second_date
    # Find the second list item (after clicking "Add another date")
    within page.all(".app-add-another__list-item")[1] do
      fill_in "Day", with: "16"
      fill_in "Month", with: "3"
      fill_in "Year", with: "2024"
    end
  end

  def and_i_click_back
    click_link "Back"
  end

  def and_i_click_continue
    click_button "Continue"
  end

  def and_i_click_add_another_date
    click_button "Add another date"
  end

  def then_i_should_be_back_on_session_edit_page
    expect(page).to have_content("Edit session")
    expect(page).to have_content(@session.location.name)
  end

  def and_the_original_dates_should_be_unchanged
    @session.reload
    expect(@session.session_dates.map(&:value)).to contain_exactly(
      @original_date1,
      @original_date2,
      @original_date3
    )
    expect(page).to have_content("15 March 2024")
    expect(page).to have_content("16 March 2024")
    expect(page).to have_content("17 March 2024")
  end

  def and_the_dates_should_be_updated
    @session.reload
    expect(@session.session_dates.map(&:value)).to contain_exactly(
      Date.new(2024, 3, 25),
      @original_date2,
      @original_date3
    )
    expect(page).to have_content("25 March 2024")
    expect(page).to have_content("16 March 2024")
    expect(page).to have_content("17 March 2024")
  end

  def and_i_should_see_both_new_dates
    @session.reload
    expect(@session.session_dates.count).to eq(2)
    expect(@session.session_dates.map(&:value)).to contain_exactly(
      Date.new(2024, 3, 15),
      Date.new(2024, 3, 16)
    )
    expect(page).to have_content("15 March 2024")
    expect(page).to have_content("16 March 2024")
  end

  def then_i_should_see_duplicate_date_error
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Session dates must be unique")
  end

  def when_i_delete_the_first_date
    within page.all(".app-add-another__list-item")[0] do
      click_button "Delete"
    end
  end

  alias_method :and_i_delete_the_new_first_date_too,
               :when_i_delete_the_first_date

  def then_i_should_only_see_the_third_date
    expect(page).to have_content("When will sessions be held?")

    expect(page).to have_field(with: "17")
    expect(page).not_to have_field(with: "16")
    expect(page).not_to have_field(with: "15")

    visible_date_groups = page.all(".app-add-another__list-item")
    expect(visible_date_groups.count).to eq(1)
  end

  def and_only_the_third_date_should_remain
    @session.reload
    expect(@session.session_dates.count).to eq(1)
    expect(@session.session_dates.first.value).to eq(@original_date3)
    expect(page).to have_content("17 March 2024")
    expect(page).not_to have_content("16 March 2024")
    expect(page).not_to have_content("15 March 2024")
  end

  def when_i_add_a_fourth_date
    # Find the fourth list item (after clicking "Add another date")
    within page.all(".app-add-another__list-item")[3] do
      fill_in "Day", with: "18"
      fill_in "Month", with: "3"
      fill_in "Year", with: "2024"
    end
  end

  def then_i_should_see_four_dates
    expect(page).to have_content("When will sessions be held?")

    visible_date_groups = page.all(".app-add-another__list-item")
    expect(visible_date_groups.count).to eq(4)

    # Check all four dates are visible
    expect(page).to have_field(with: "15")
    expect(page).to have_field(with: "16")
    expect(page).to have_field(with: "17")
    expect(page).to have_field(with: "18")
  end

  def when_i_delete_the_newly_added_fourth_date
    within page.all(".app-add-another__list-item")[3] do
      click_button "Delete"
    end
  end

  def then_i_should_see_original_three_dates_only
    expect(page).to have_content("When will sessions be held?")

    visible_date_groups = page.all(".app-add-another__list-item")
    expect(visible_date_groups.count).to eq(3)

    # Check only original three dates are visible
    expect(page).to have_field(with: "15")
    expect(page).to have_field(with: "16")
    expect(page).to have_field(with: "17")
    expect(page).not_to have_field(with: "18")
  end

  def when_i_add_an_invalid_date
    fill_in "Day", with: "29"
    fill_in "Month", with: "2"
    fill_in "Year", with: "2023" # Not a leap year
  end

  def when_i_add_an_incomplete_date
    fill_in "Day", with: "15"
    fill_in "Month", with: ""
    fill_in "Year", with: "2024"
  end

  def then_i_should_see_invalid_date_error
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Enter a valid date")
  end

  def given_i_have_a_session_with_dates_and_attendances
    @team = create(:team, :with_one_nurse)
    @session = create(:session, :unscheduled, team: @team)
    @original_date1 = Date.new(2024, 3, 15)
    @original_date2 = Date.new(2024, 3, 16)
    @original_date3 = Date.new(2024, 3, 17)

    # Create session dates
    @session_date1 = @session.session_dates.create!(value: @original_date1)
    @session_date2 = @session.session_dates.create!(value: @original_date2)
    @session_date3 = @session.session_dates.create!(value: @original_date3)

    # Create a patient and patient session
    @patient = create(:patient, team: @team)
    @patient_session =
      create(:patient_session, patient: @patient, session: @session)

    # Create session attendance for the first date (this will prevent changing that date)
    create(
      :session_attendance,
      :present,
      patient_session: @patient_session,
      session_date: @session_date1
    )

    sign_in @team.users.first
  end

  def then_i_see_the_session_dates_page_with_attendance_restrictions
    expect(page).to have_content("When will sessions be held?")

    # First date should be read-only (has attendances)
    within page.all(".app-add-another__list-item")[0] do
      expect(page).to have_content("15 March 2024")
      expect(page).to have_content(
        "Children have attended this session. It cannot be changed."
      )
      expect(page).not_to have_field("Day")
    end

    # Second and third dates should be editable (no attendances)
    within page.all(".app-add-another__list-item")[1] do
      expect(page).to have_field("Day", with: "16")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end

    within page.all(".app-add-another__list-item")[2] do
      expect(page).to have_field("Day", with: "17")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end
  end

  def then_i_should_see_no_dates_error
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Enter a date")
  end

  def then_i_see_the_single_session_date
    expect(page).to have_content("15 March 2024")
  end

  def then_i_see_the_session_dates_page_with_one_date
    expect(page).to have_content("When will sessions be held?")

    visible_date_groups = page.all(".app-add-another__list-item")
    expect(visible_date_groups.count).to eq(1)

    within visible_date_groups[0] do
      expect(page).to have_field("Day", with: "15")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end
  end

  def when_i_try_to_delete_the_only_date
    within page.all(".app-add-another__list-item")[0] do
      click_button "Delete"
    end
  end

  def then_i_should_see_cannot_delete_last_date_error
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("You cannot delete the last session date")
    expect(page).to have_content("A session must have at least one date")
  end

  def and_the_date_should_still_be_visible
    visible_date_groups = page.all(".app-add-another__list-item")
    expect(visible_date_groups.count).to eq(1)

    within visible_date_groups[0] do
      expect(page).to have_field("Day", with: "15")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2024")
    end
  end
end
