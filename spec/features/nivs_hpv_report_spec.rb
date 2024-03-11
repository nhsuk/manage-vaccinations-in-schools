require "rails_helper"

RSpec.describe "NIVS HPV report" do
  scenario "User downloads the NIVS HPV report" do
    given_i_am_signed_in
    when_i_go_to_the_reports_page
    # and_i_download_the_nivs_hpv_report
    # then_i_should_see_all_the_administered_vaccinations_from_my_teams_hpv_campaign
  end

  def given_i_am_signed_in
    @user = create(:user, :admin)
    sign_in @user
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse, :with_one_location)
    sign_in team.users.first
  end

  def when_i_go_to_the_reports_page
    visit "/dashboard"
    click_on "Reports", match: :first

    expect(page).to have_css("h1", text: "Reports")
  end
end
