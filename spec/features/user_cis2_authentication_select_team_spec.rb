# frozen_string_literal: true

describe "User CIS2 authentication", :cis2 do
  scenario "select a team" do
    given_an_organisation_exists_with_multiple_teams
    and_i_belong_to_the_teams

    when_i_sign_in
    then_i_am_required_to_select_a_team

    when_i_choose_a_team
    then_i_am_logged_in
  end

  def given_an_organisation_exists_with_multiple_teams
    @organisation = create(:organisation, ods_code: "ABC")
    @teams = create_list(:team, 3, organisation: @organisation)
  end

  def and_i_belong_to_the_teams
    @user = create(:nurse, teams: @teams)
  end

  def when_i_sign_in
    sign_in @user
  end

  def then_i_am_required_to_select_a_team
    expect(page).to have_content("Select a team")
  end

  def when_i_choose_a_team
    choose @teams.sample.name
    click_on "Continue"
  end

  def then_i_am_logged_in
    expect(page).to have_content("USER, Test")
    expect(page).to have_button("Log out")
  end
end
