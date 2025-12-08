# frozen_string_literal: true

describe "Edit session dates" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "adding dates to a new session" do
    given_a_session_exists

    when_i_visit_the_session_overview_page
    and_i_click_on_schedule_sessions
    and_i_click_on_add_session_dates

    when_i_add_a_date_in_the_future
    then_i_see_the_confirm_page
    and_i_save_the_changes
  end

  scenario "adding dates with a high number of unvaccinated catch up patients" do
    given_a_session_exists
    and_the_session_has_unvaccinated_catch_up_patients

    when_i_visit_the_session_overview_page
    and_i_click_on_schedule_sessions
    and_i_click_on_add_session_dates

    when_i_add_a_date_in_the_future
    then_i_see_the_warning_panel_about_unvaccinated_patients
    and_i_keep_the_dates
    and_i_save_the_changes
  end

  def given_a_session_exists
    programmes = [Programme.hpv]

    @team = create(:team, :with_one_nurse, programmes:)
    @session = create(:session, :unscheduled, programmes:, team: @team)
  end

  def and_the_session_has_unvaccinated_catch_up_patients
    create(:patient, :vaccinated, session: @session, year_group: 9)
    create_list(
      :patient,
      9,
      :eligible_for_vaccination,
      session: @session,
      year_group: 9
    )
  end

  def when_i_visit_the_session_overview_page
    sign_in @team.users.first
    visit session_path(@session)
  end

  def and_i_click_on_schedule_sessions
    click_on "Edit session"
  end

  def and_i_click_on_add_session_dates
    click_on "Add session dates"
  end

  def when_i_add_a_date_in_the_future
    fill_in "Day", with: "1"
    fill_in "Month", with: "5"
    fill_in "Year", with: "2024"
    click_on "Continue"
  end

  def then_i_see_the_confirm_page
    expect(page).to have_content("Edit session")
    expect(page).to have_content("Session datesWednesday, 1 May 2024")
  end

  def then_i_see_the_warning_panel_about_unvaccinated_patients
    expect(page).to have_content(
      "Have you imported historical vaccination records for HPV?"
    )
    expect(page).to have_content(
      "Only 10% of children in Years 9, 10, and 11 in this session have vaccination records."
    )
    expect(page).to have_content(
      "Scheduling this session now will send consent requests to 9 parents " \
        "of children in Years 9, 10, and 11 on 10 April 2024. Many " \
        "of them may be parents of already vaccinated children."
    )
  end

  def and_i_keep_the_dates
    click_on "Keep session dates"
  end

  def and_i_save_the_changes
    click_on "Save changes"
  end
end
