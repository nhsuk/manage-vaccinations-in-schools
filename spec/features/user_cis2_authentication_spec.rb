# frozen_string_literal: true

describe "User CIS2 authentication", :cis2 do
  before { given_a_test_team_is_setup_in_mavis_and_cis2 }

  scenario "as a medical secretary" do
    given_an_admin_user_is_mocked

    when_i_go_to_the_start_page
    then_i_should_see_the_cis2_login_button

    when_i_click_the_cis2_login_button
    and_i_am_logged_in_as_an_admin
    and_i_am_added_to_the_team
    and_i_am_not_marked_as_a_pgd_supplier

    when_i_click_the_change_role_button
    then_i_see_the_dashboard

    when_i_log_out
    then_i_am_on_the_start_page
    and_i_am_logged_out
  end

  scenario "as a nurse" do
    given_a_nurse_user_is_mocked

    when_i_go_to_the_start_page
    then_i_should_see_the_cis2_login_button

    when_i_click_the_cis2_login_button
    and_i_am_logged_in_as_a_nurse
    and_i_am_added_to_the_team
    and_i_am_marked_as_a_pgd_supplier

    when_i_click_the_change_role_button
    then_i_see_the_dashboard

    when_i_log_out
    then_i_am_on_the_start_page
    and_i_am_logged_out
  end

  def given_a_test_team_is_setup_in_mavis_and_cis2
    @user = create(:user, uid: "123")
    @team = create(:team, users: [@user])
  end

  def given_a_nurse_user_is_mocked
    mock_cis2_auth(
      uid: @user.uid,
      given_name: "Nurse",
      family_name: "Test",
      org_code: @team.organisation.ods_code,
      org_name: @team.name,
      workgroups: [@team.workgroup]
    )
  end

  def given_an_admin_user_is_mocked
    mock_cis2_auth(
      uid: @user.uid,
      given_name: "Admin",
      family_name: "Test",
      role_code: CIS2Info::MEDICAL_SECRETARY_ROLE,
      org_code: @team.organisation.ods_code,
      org_name: @team.name,
      workgroups: [@team.workgroup]
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

  def and_i_am_logged_in_as_an_admin
    expect(page).to have_content("TEST, Admin")
    expect(page).to have_button "Log out"
  end

  def and_i_am_logged_in_as_a_nurse
    expect(page).to have_content("TEST, Nurse")
    expect(page).to have_button "Log out"
  end

  def and_i_am_added_to_the_team
    user = User.first
    expect(user).not_to be_nil
    expect(user.teams).to include(@team)
  end

  def and_i_am_not_marked_as_a_pgd_supplier
    expect(@user.reload).not_to be_show_in_suppliers
  end

  def and_i_am_marked_as_a_pgd_supplier
    expect(@user.reload).to be_show_in_suppliers
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
    expect(page).not_to have_content("TEST, Admin")
    expect(page).not_to have_content("TEST, Nurse")
    expect(page).not_to have_button("Log out")
  end
end
