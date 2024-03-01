require "rails_helper"

RSpec.describe "Manage batches" do
  before { Timecop.freeze(Time.zone.local(2024, 2, 29)) }
  after { Timecop.return }

  scenario "Add a new batch" do
    given_my_team_is_running_an_hpv_vaccination_campaign

    when_i_manage_vaccines
    then_i_see_an_hpv_vaccine_with_no_batches_set_up

    when_i_add_a_new_batch
    then_i_see_the_batch_i_just_added_on_the_vaccines_page
  end

  def given_my_team_is_running_an_hpv_vaccination_campaign
    @team = create(:team, :with_one_nurse)
    create(:campaign, :hpv_no_batches, team: @team)
  end

  def when_i_manage_vaccines
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Manage vaccines", match: :first
  end

  def then_i_see_an_hpv_vaccine_with_no_batches_set_up
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).not_to have_css("table")
  end

  def when_i_add_a_new_batch
    click_on "Add batch"

    fill_in "Batch", with: "AB1234"

    # expiry date
    fill_in "Day", with: "30"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"

    click_on "Add batch"

    expect(page).to have_content("Batch AB1234 added")
  end

  def then_i_see_the_batch_i_just_added_on_the_vaccines_page
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).to have_css("table")
    expect(page).to have_content(
      [
        "AB1234",
        "29 February 2024", # date entered
        "30 March 2024" # expiry
      ].join("")
    )
  end
end
