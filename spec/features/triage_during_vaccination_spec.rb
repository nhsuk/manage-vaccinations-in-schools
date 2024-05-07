require "rails_helper"

RSpec.describe "Triage" do
  include EmailExpectations

  scenario "during vaccination" do
    given_a_campaign_with_a_running_session
    and_a_patient_needing_triage
    and_i_am_signed_in

    when_i_go_to_the_vaccinations_page
    and_i_go_to_the_patient_that_needs_triage
    and_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_vaccinations_page
    and_i_should_see_that_the_patient_is_ready_for_vaccination
  end

  def given_a_campaign_with_a_running_session
    @team = create(:team, :with_one_nurse, :with_one_location)
    @campaign = create(:campaign, :hpv, team: @team)
    @batch = @campaign.batches.first
    @session =
      create(:session, campaign: @campaign, location: @team.locations.first)
  end

  def and_a_patient_needing_triage
    @patient =
      create(
        :patient_with_consent_given_triage_needed,
        session: @session,
        location: @session.location
      )
  end

  def and_i_am_signed_in
    sign_in @team.users.first
  end

  def when_i_go_to_the_vaccinations_page
    visit session_vaccinations_path(@session)
  end

  def and_i_go_to_the_patient_that_needs_triage
    click_link @patient.full_name
  end

  def and_i_record_that_they_are_safe_to_vaccinate
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def then_i_see_the_vaccinations_page
    expect(page).to have_content("Record vaccinations")
  end

  def and_i_should_see_that_the_patient_is_ready_for_vaccination
    within("tr", text: @patient.full_name) do
      expect(page).to have_content("Vaccinate")
    end
  end
end
