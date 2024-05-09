require "rails_helper"

RSpec.describe "Batch management" do
  before { Timecop.freeze(Time.zone.local(2024, 2, 29)) }
  after { Timecop.return }

  scenario "Adding a new batch" do
    given_my_team_is_running_an_hpv_vaccination_campaign
    and_there_is_a_vaccination_session_today_at_one_of_my_teams_schools

    when_i_manage_vaccines
    then_i_see_an_hpv_vaccine_with_no_batches_set_up

    when_i_add_a_new_batch
    then_i_see_the_batch_i_just_added_on_the_vaccines_page

    when_i_set_the_batch_as_default
    and_i_start_vaccinating_a_patient
    then_i_am_not_asked_to_select_a_batch
    and_the_batch_is_recorded_against_the_patient
  end

  def given_my_team_is_running_an_hpv_vaccination_campaign
    @team = create(:team, :with_one_nurse, :with_one_location)
    @campaign = create(:campaign, :hpv_no_batches, team: @team)
  end

  def and_there_is_a_vaccination_session_today_at_one_of_my_teams_schools
    session =
      create(
        :session,
        :in_progress,
        campaign: @campaign,
        location: @team.locations.first,
        patients_in_session: 1
      )

    @patient = session.patients.first
  end

  def when_i_manage_vaccines
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Vaccines", match: :first
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
    expect(page).to have_content("AB1234 29 February 202430 March 2024")
  end

  def when_i_set_the_batch_as_default
    click_on "Make default"
  end

  def and_i_start_vaccinating_a_patient
    click_on "Campaigns", match: :first
    click_on @campaign.name
    click_on @team.locations.first.name
    click_on "Record vaccinations"

    # patient is in the "get consent state" so need to get to the vaccination state
    record_self_consent

    click_on @patient.full_name
    choose "Yes, they got the HPV vaccine"
    choose "Left arm (upper position)"

    click_on "Continue"
  end

  def record_self_consent
    click_on @patient.full_name

    click_on "Assess Gillick competence"
    click_on "Give your assessment"

    choose "Yes, they are Gillick competent"

    fill_in "Give details of your assessment",
            with: "They understand the benefits and risks of the vaccine"
    click_on "Continue"

    # record consent
    choose "Yes, they agree"
    click_on "Continue"

    # answer the health questions
    all("label", text: "No").each(&:click)
    choose "Yes, it’s safe to vaccinate"
    click_on "Continue"

    # confirmation page
    click_on "Confirm"

    expect(page).to have_content("Record vaccinations")
  end

  def then_i_am_not_asked_to_select_a_batch
    expect(page).not_to have_content("Which batch did you use?")
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("AB1234")

    click_on "Confirm"
  end

  def and_the_batch_is_recorded_against_the_patient
    expect(page).to have_content("Record saved for #{@patient.full_name}")

    click_on "View child record"

    expect(page).to have_content("Vaccinated")
    expect(page).to have_content("HPV (Gardasil 9, AB1234)")
  end
end
