# frozen_string_literal: true

describe "User CIS2 authentication", :cis2 do
  scenario "user does not have a role selected" do
    given_i_am_setup_in_mavis_and_cis2_but_with_an_empty_role
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page
    when_i_click_the_cis2_login_button
    then_i_see_the_wrong_workgroup_error
  end

  def given_i_am_setup_in_mavis_and_cis2_but_with_an_empty_role
    @organisation = create :organisation, ods_code: "AB12"

    mock_cis2_auth(selected_roleid: "")
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

  def then_i_see_the_wrong_workgroup_error
    expect(
      page
    ).to have_heading "You’re not in the right workgroup to use this service"
  end
end
