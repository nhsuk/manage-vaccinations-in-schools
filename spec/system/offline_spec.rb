require "rails_helper"

RSpec.describe "Offline mode" do
  it "works correctly" do
    @campaign = create(:campaign)
    visit root_path
    click_link @campaign.location.name
    # click_button "Save offline"
    when_i_go_offline
    visit campaign_vaccinations_path(@campaign)
    # visit root_path
    # click_link "Record vaccinations"
    expect(page).to have_content "foo"
    # click_link @campaign.children.first.full_name
  end

  private

  def when_i_go_offline
    page.driver.browser.page.command(
      "Network.emulateNetworkConditions",
      offline: true,
      latency: 0,
      downloadThroughput: 0,
      uploadThroughput: 0
    )
  end
end
