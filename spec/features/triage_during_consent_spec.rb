require "rails_helper"

RSpec.describe "Triage" do
  include EmailExpectations

  scenario "during consent" do
    given_a_campaign_with_a_running_session
    and_a_patient_needing_triage
    and_i_am_signed_in

    when_i_go_to_the_given_tab_of_the_consents_page
    and_i_go_to_the_patient_that_needs_triage
    and_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_consents_page
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
        :patient_session,
        :consent_given_triage_needed,
        session: @session
      ).patient
  end

  def and_i_am_signed_in
    sign_in @team.users.first
  end

  def when_i_go_to_the_given_tab_of_the_consents_page
    visit session_consents_tab_path(@session, tab: "given")
  end

  def and_i_go_to_the_patient_that_needs_triage
    click_link @patient.full_name
  end

  def and_i_record_that_they_are_safe_to_vaccinate
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def then_i_see_the_consents_page
    expect(page).to have_content("Check consent responses")
  end
end
