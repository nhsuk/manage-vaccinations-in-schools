# frozen_string_literal: true

describe "User CIS2 authentication", :cis2 do
  scenario "from start page" do
    given_a_test_organisation_is_setup_in_mavis_and_cis2
    when_i_go_to_the_start_page
    then_i_should_see_the_cis2_login_button

    when_i_click_the_cis2_login_button
    then_i_see_the_dashboard
    and_i_am_logged_in

    when_i_click_the_change_role_button
    then_i_see_the_dashboard

    when_i_log_out
    then_i_am_on_the_start_page
    and_i_am_logged_out
  end

  scenario "going straight to the sessions page" do
    given_a_test_organisation_is_setup_in_mavis_and_cis2
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page

    when_i_click_the_cis2_login_button
    then_i_see_the_sessions_page
    and_i_am_logged_in
  end

  def given_a_test_organisation_is_setup_in_mavis_and_cis2
    @organisation = create :organisation

    mock_cis2_auth(
      uid: "123",
      given_name: "Nurse",
      family_name: "Test",
      org_code: @organisation.ods_code,
      org_name: @organisation.name
    )
  end

  def when_i_go_to_the_start_page
    visit "/start"
  end

  def then_i_should_see_the_cis2_login_button
    expect(page).to have_button "Log in with my Care Identity"
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def then_i_see_the_dashboard
    expect(page).to have_current_path dashboard_path
  end

  def and_i_am_logged_in
    expect(page).to have_content("TEST, Nurse")
    expect(page).to have_button "Log out"
  end

  def when_i_click_the_change_role_button
    click_button "Change role"
  end

  def when_i_log_out
    click_button "Log out"
  end

  def then_i_am_on_the_start_page
    expect(page).to have_current_path start_path
  end

  def and_i_am_logged_out
    expect(page).not_to have_content("TEST, Nurse")
    expect(page).not_to have_button("Log out")
  end

  def when_i_go_to_the_sessions_page
    visit sessions_path
  end

  def then_i_see_the_sessions_page
    expect(page).to have_current_path sessions_path
  end
end
