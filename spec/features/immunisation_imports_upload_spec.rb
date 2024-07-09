# frozen_string_literal: true

require "rails_helper"

describe "Immunisation imports" do
  scenario "User uploads a file" do
    given_i_am_signed_in
    and_an_hpv_campaign_is_underway

    when_i_go_to_the_reports_page
    then_i_should_see_the_upload_link
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, :with_one_location)
    sign_in @team.users.first
  end

  def and_an_hpv_campaign_is_underway
    campaign = create(:campaign, :hpv, team: @team)
    @session = create(:session, campaign:, location: @team.locations.first)
  end

  def when_i_go_to_the_reports_page
    visit "/dashboard"

    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Reports"
  end

  def then_i_should_see_the_upload_link
    expect(page).to have_link("Upload vaccination events (CSV)")
  end
end
