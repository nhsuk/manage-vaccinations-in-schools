require "rails_helper"

RSpec.describe "Triage" do
  include EmailExpectations

  scenario "nurse can triage a patient" do
    given_a_campaign_with_a_running_session
    when_i_go_to_the_patient_that_needs_triage
    then_i_see_the_triage_options

    when_i_save_the_triage_without_choosing_an_option
    then_i_see_a_validation_error

    when_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_triage_page
    and_an_email_is_sent_to_the_parent
  end

  def given_a_campaign_with_a_running_session
    @team = create(:team, :with_one_nurse, :with_one_location)
    @campaign = create(:campaign, :hpv, team: @team)
    @batch = @campaign.batches.first
    @session =
      create(:session, campaign: @campaign, location: @team.locations.first)
    @patient =
      create(
        :patient_session,
        :consent_given_triage_needed,
        session: @session
      ).patient
  end

  def when_i_go_to_the_patient_that_needs_triage
    sign_in @team.users.first
    visit session_triage_tab_path(@session, tab: "needed")
    click_link @patient.full_name
  end

  def when_i_record_that_they_are_safe_to_vaccinate
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def then_i_see_the_triage_page
    expect(page).to have_selector :heading, "Triage"
  end

  def then_i_see_the_triage_options
    expect(page).to have_selector :heading, "Is it safe to vaccinate"
  end

  def when_i_save_the_triage_without_choosing_an_option
    click_button "Save triage"
  end

  def then_i_see_a_validation_error
    expect(page).to have_selector :heading, "There is a problem"
  end

  def and_an_email_is_sent_to_the_parent
    expect_email_to @patient.consents.first.parent_email,
                    EMAILS[:triage_vaccination_will_happen]
  end
end
