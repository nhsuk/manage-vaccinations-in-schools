# frozen_string_literal: true

describe "User CIS2 authentication" do
  scenario "user has wrong organisation selected" do
    given_i_am_setup_in_cis2_but_not_mavis
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page

    when_i_click_the_cis2_login_button
    then_i_see_the_organisation_not_found_error

    given_my_organisation_has_been_setup_in_mavis
    when_i_click_the_change_role_button
    then_i_see_the_sessions_page
  end

  context "user has no other orgs to select" do
    scenario "user has wrong organisation selected" do
      given_i_am_setup_in_cis2_with_only_one_org
      when_i_go_to_the_start_page
      then_i_should_see_the_cis2_login_button

      when_i_click_the_cis2_login_button
      then_i_see_the_organisation_not_found_error
      and_there_is_no_change_role_button
    end
  end

  def setup_cis2_auth_mock
    OmniAuth.config.add_mock(:cis2, cis2_auth_mock)
  end

  def given_i_am_setup_in_cis2_but_not_mavis
    mock_cis2_auth(
      uid: "123",
      given_name: "Nurse",
      family_name: "Test",
      org_code: "A9A5A",
      org_name: "SAIS Organisation"
    )
  end

  def given_my_organisation_has_been_setup_in_mavis
    @organisation = create :organisation, ods_code: "A9A5A"
  end

  def when_i_go_to_the_start_page
    visit "/start"
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def then_i_am_on_the_start_page
    expect(page).to have_current_path start_path
  end

  def when_i_go_to_the_sessions_page
    visit sessions_path
  end

  def then_i_see_the_sessions_page
    expect(page).to have_current_path sessions_path
  end

  def given_i_am_setup_in_cis2_with_only_one_org
    mock_cis2_auth(
      uid: "123",
      given_name: "Nurse",
      family_name: "Test",
      org_code: "A9A5A",
      org_name: "SAIS Organisation",
      user_only_has_one_org: true
    )
  end

  def then_i_see_the_organisation_not_found_error
    expect(
      page
    ).to have_heading "Your organisation is not using this service yet"
  end

  def when_i_click_the_change_role_button
    click_button "Change role"
  end

  def and_there_is_no_change_role_button
    expect(page).not_to have_button "Change role"
  end

  def then_i_should_see_the_cis2_login_button
    expect(page).to have_button "Log in with my Care Identity"
  end
end
