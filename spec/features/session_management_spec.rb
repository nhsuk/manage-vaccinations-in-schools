# frozen_string_literal: true

describe "Session management" do
  around { |example| travel_to(Time.zone.local(2024, 2, 29)) { example.run } }

  scenario "Adding a new session, closing consent" do
    given_my_team_is_running_an_hpv_vaccination_programme
    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_no_sessions

    when_i_add_a_new_session
    then_i_see_the_list_of_schools

    when_i_choose_a_school
    then_i_see_the_date_step

    when_i_choose_the_date
    then_i_see_the_cohort_step

    when_i_choose_the_cohort
    then_i_see_the_timeline_page

    when_i_choose_the_timeline
    then_i_see_the_confirmation_page

    when_i_confirm
    then_i_should_see_the_session_details
    and_the_parents_should_receive_a_consent_request

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_no_sessions

    when_the_parent_visits_the_consent_form
    then_they_can_give_consent

    when_the_deadline_has_passed
    then_they_can_no_longer_give_consent

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_the_new_session
  end

  def given_my_team_is_running_an_hpv_vaccination_programme
    @team = create(:team, :with_one_nurse)
    create(:programme, :hpv, team: @team)
    @location = create(:location, :school)
    @patient = create(:patient, school: @location)
  end

  def when_i_go_to_todays_sessions_as_a_nurse
    sign_in @team.users.first
    visit "/dashboard"
    click_link "Today’s sessions", match: :first
  end

  def then_i_see_no_sessions
    expect(page).to have_content("There are no sessions")
  end

  def when_i_add_a_new_session
    click_button "Add a new session"
  end

  def then_i_see_the_list_of_schools
    expect(page).to have_content(@location.name)
  end

  def when_i_choose_a_school
    choose @location.name
    click_button "Continue"
  end

  def then_i_see_the_date_step
    expect(page).to have_content("When is the session?")
  end

  def when_i_choose_the_date
    fill_in "Day", with: "10"
    fill_in "Month", with: "03"
    fill_in "Year", with: "2024"

    choose "Morning"
    click_button "Continue"
  end

  def then_i_see_the_cohort_step
    expect(page).to have_content("Choose cohort for this session")
  end

  def when_i_choose_the_cohort
    click_button "Continue"
  end

  def then_i_see_the_timeline_page
    expect(page).to have_content("What’s the timeline for consent requests?")
  end

  def when_i_choose_the_timeline
    fill_in "Day", with: "29", match: :first
    fill_in "Month", with: "02", match: :first
    fill_in "Year", with: "2024", match: :first

    choose "2 days after the first consent request"

    choose "Allow responses until the day of the session"

    click_button "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm details")
    expect(page).to have_content("After clicking confirm")
  end

  def when_i_confirm
    click_button "Confirm"
  end

  def then_i_should_see_the_session_details
    expect(page).to have_content(@location.name.to_s)
  end

  def and_the_parents_should_receive_a_consent_request
    @patient.parents.each do |parent|
      expect_email_to(parent.email, :hpv_session_consent_request, :any)
      expect_text_to(parent.phone, :consent_request, :any)
    end
  end

  def when_the_parent_visits_the_consent_form
    visit start_session_parent_interface_consent_forms_path(Session.last)
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
    visit start_session_parent_interface_consent_forms_path(Session.last)
    expect(page).to have_content("The deadline for responding has passed")
  end

  def then_i_see_the_new_session
    expect(page).to have_content(@location.name)
  end
end
