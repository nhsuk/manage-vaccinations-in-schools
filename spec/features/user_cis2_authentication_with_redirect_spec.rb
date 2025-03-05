# frozen_string_literal: true

describe "User CIS2 authentication" do
  scenario "with redirect" do
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

  def when_i_go_to_the_sessions_page
    visit sessions_path
  end

  def then_i_am_on_the_start_page
    expect(page).to have_current_path start_path
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def then_i_see_the_sessions_page
    expect(page).to have_current_path sessions_path
  end

  def and_i_am_logged_in
    expect(page).to have_content("TEST, Nurse")
    expect(page).to have_button("Log out")
  end

  def then_i_see_the_organisation_not_found_error
    expect(page).to have_heading(
      "Your organisation is not using this service yet"
    )
  end

  def when_i_click_the_change_role_button
    click_button "Change role"
  end

  def then_i_see_the_organisation_not_found_error
    expect(
      page
    ).to have_heading "Your organisation is not using this service yet"
  end

  def and_there_is_no_change_role_button
    expect(page).not_to have_button "Change role"
  end
end
