# frozen_string_literal: true

describe "Manage teams" do
  scenario "Viewing team settings" do
    given_my_team_exists

    when_i_click_on_team_settings
    then_i_see_the_team_contact_details

    when_i_click_on_clinics
    then_i_see_the_team_clinics

    when_i_click_on_schools
    then_i_see_the_team_schools

    when_i_click_on_sessions
    then_i_see_the_team_sessions
  end

  def given_my_team_exists
    @team = create(:team, :with_one_nurse)
    create(:school, team: @team)
    create(:community_clinic, team: @team)
  end

  def when_i_click_on_team_settings
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Your team", match: :first
  end

  def then_i_see_the_team_contact_details
    expect(page).to have_content("Contact details")
  end

  def when_i_click_on_clinics
    click_on "Clinics"
  end

  def then_i_see_the_team_clinics
    expect(page).to have_content("Clinics")
    expect(page).to have_content(@team.community_clinics.first.name)
    expect(page).to have_content(@team.community_clinics.first.address_line_1)
  end

  def when_i_click_on_schools
    find(".app-sub-navigation__link", text: "Schools").click
  end

  def then_i_see_the_team_schools
    expect(page).to have_content("Schools")
    expect(page).to have_content(@team.schools.first.name)
    expect(page).to have_content(@team.schools.first.address_line_1)
  end

  def when_i_click_on_sessions
    find(".app-sub-navigation__link", text: "Sessions").click
  end

  def then_i_see_the_team_sessions
    expect(page).to have_content("Session defaults")
  end
end
