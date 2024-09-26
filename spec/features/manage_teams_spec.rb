# frozen_string_literal: true

describe "Manage teams" do
  scenario "Viewing team settings" do
    given_my_team_exists

    when_i_click_on_team_settings
    then_i_see_the_team_settings
  end

  def given_my_team_exists
    @team = create(:team, :with_one_nurse)
  end

  def when_i_click_on_team_settings
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Team settings"
  end

  def then_i_see_the_team_settings
    expect(page).to have_content("Contact details")
    expect(page).to have_content("Session defaults")
  end
end
