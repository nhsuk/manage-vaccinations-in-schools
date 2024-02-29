require "rails_helper"

require "rake"

RSpec.feature "Manage batches", type: :feature do
  before do
    Rails.application.load_tasks
    Timecop.freeze(Time.zone.local(2024, 2, 29)) # so we don't worry about expiry dates
  end

  after { Timecop.return }

  scenario "Add a new batch" do
    given_my_team_is_running_an_hpv_vaccination_campaign

    when_i_manage_vaccines
    then_i_see_an_hpv_vaccine_with_no_batches_set_up

    when_i_add_a_new_batch
    then_i_see_the_batch_i_just_added_on_the_vaccines_page
  end

  def given_my_team_is_running_an_hpv_vaccination_campaign
    team = build(:team) # get some fake data

    suppress_output do
      Rake::Task["add_new_hpv_team"].invoke(
        team.email,
        team.name,
        team.phone,
        team.ods_code,
        team.privacy_policy_url,
        team.reply_to_id
      )
    end

    created_team = Team.find_by(email: team.email)

    suppress_output do
      Rake::Task["add_new_user"].invoke(
        "nurse.testy@example.com",
        "nurse.testy@example.com",
        "Nurse Testy",
        created_team.id,
        ""
      )
    end
  end

  def when_i_manage_vaccines
    sign_in_as_nurse_testy

    click_on "Manage vaccines"
  end

  def sign_in_as_nurse_testy
    if page.current_url.present? && page.has_content?("Sign out")
      click_on "Sign out"
    end

    visit "/dashboard"
    fill_in "Email address", with: "nurse.testy@example.com"
    fill_in "Password", with: "nurse.testy@example.com"
    click_button "Sign in"
    expect(page).to have_content("Signed in successfully.")
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

  def suppress_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
