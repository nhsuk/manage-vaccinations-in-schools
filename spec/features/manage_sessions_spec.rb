# frozen_string_literal: true

describe "Manage sessions" do
  around { |example| travel_to(Time.zone.local(2024, 2, 18)) { example.run } }

  scenario "Adding a new session, closing consent" do
    given_my_team_is_running_an_hpv_vaccination_programme

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_no_sessions

    when_i_go_to_unscheduled_sessions
    then_i_see_the_school

    when_i_click_on_the_school
    then_i_see_the_school_session

    when_i_click_on_schedule_sessions
    then_i_see_the_dates_page

    when_i_choose_the_dates
    then_i_see_the_confirmation_page

    when_i_confirm
    then_i_should_see_the_session_details

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_no_sessions

    when_i_go_to_scheduled_sessions
    then_i_see_the_school

    when_the_parent_visits_the_consent_form
    then_they_can_give_consent

    when_the_deadline_has_passed
    then_they_can_no_longer_give_consent

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_the_school

    when_i_go_to_unscheduled_sessions
    then_i_see_no_sessions

    when_i_go_to_scheduled_sessions
    then_i_see_the_school

    when_i_go_to_completed_sessions
    then_i_see_no_sessions
  end

  def given_my_team_is_running_an_hpv_vaccination_programme
    @programme = create(:programme, :hpv)
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    @location = create(:location, :secondary, team: @team)
    @patient =
      create(
        :patient,
        date_of_birth: 13.years.ago.to_date,
        school: @location,
        team: @team
      )
  end

  def when_i_go_to_todays_sessions_as_a_nurse
    sign_in @team.users.first
    visit "/dashboard"
    click_link "Sessions", match: :first
  end

  def when_i_go_to_unscheduled_sessions
    click_link "Unscheduled"
  end

  def when_i_go_to_scheduled_sessions
    click_link "Scheduled"
  end

  def when_i_go_to_completed_sessions
    click_link "Completed"
  end

  def then_i_see_no_sessions
    expect(page).to have_content(/There are no (sessions|schools)/)
  end

  def when_i_click_on_the_school
    click_link @location.name
  end

  def then_i_see_the_school_session
    expect(page).to have_content(@location.name)
    expect(page).to have_content("No sessions scheduled")
    expect(page).to have_content("Schedule sessions")
  end

  def when_i_click_on_schedule_sessions
    click_on "Schedule sessions"
    click_on "Add session dates"
  end

  def then_i_see_the_dates_page
    expect(page).to have_content("When will sessions be held?")
  end

  def when_i_choose_the_dates
    fill_in "Day", with: "10"
    fill_in "Month", with: "03"
    fill_in "Year", with: "2024"
    click_on "Add another date"

    within all(".app-add-another__list-item")[1] do
      fill_in "Day", with: "11"
      fill_in "Month", with: "03"
      fill_in "Year", with: "2024"
    end
    click_on "Add another date"

    within all(".app-add-another__list-item")[2] do
      fill_in "Day", with: "12"
      fill_in "Month", with: "03"
      fill_in "Year", with: "2024"
    end

    click_on "Add another date"

    within all(".app-add-another__list-item")[3] do
      click_on "Delete"
    end

    within all(".app-add-another__list-item")[2] do
      click_on "Delete"
    end

    click_on "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Edit session")
  end

  def when_i_confirm
    click_on "Continue"
  end

  def then_i_should_see_the_session_details
    expect(page).to have_content(@location.name.to_s)
    expect(page).to have_content("10 March 2024")
    expect(page).to have_content("11 March 2024")
  end

  def when_the_parent_visits_the_consent_form
    visit start_parent_interface_consent_forms_path(Session.last, @programme)
  end

  def then_they_can_give_consent
    expect(page).to have_content(
      "Give or refuse consent for an HPV vaccination"
    )
  end

  def when_the_deadline_has_passed
    travel_to(Time.zone.local(2024, 3, 10))
  end

  def then_they_can_no_longer_give_consent
    visit start_parent_interface_consent_forms_path(Session.last, @programme)
    expect(page).to have_content("The deadline for responding has passed")
  end

  def then_i_see_the_school
    expect(page).to have_content(@location.name)
  end
end
