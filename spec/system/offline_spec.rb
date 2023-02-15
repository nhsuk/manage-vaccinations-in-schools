require "rails_helper"

RSpec.describe "Offline mode" do
  it "works correctly" do
    @campaign = create(:campaign)
    visit root_path
    click_link @campaign.location.name
    click_button "Save offline"
    # binding.irb
    # page.driver.wait_for_network_idle
    # binding.irb
    page.driver.browser.network.offline_mode
    WebMock.disable_net_connect!(allow_localhost: false)
    # binding.irb
    click_link "Record vaccinations"
    click_link @campaign.children.first.full_name
    binding.irb
    # page.driver.debug(binding)
  end

  private
end
