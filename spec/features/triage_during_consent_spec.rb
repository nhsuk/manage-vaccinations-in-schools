require "rails_helper"

RSpec.describe "Triage" do
  include EmailExpectations

  scenario "during consent" do
    given_a_campaign_with_a_running_session
    and_a_patient_needing_triage
    and_i_am_signed_in

    when_i_go_to_the_patient_that_needs_triage
    then_i_see_the_triage_options

    when_i_save_the_triage_without_choosing_an_option
    then_i_see_a_validation_error

    when_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_consents_page
    and_an_email_is_sent_to_the_parent
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

  def when_i_go_to_the_patient_that_needs_triage
    visit session_consents_tab_path(@session, tab: "given")
    click_link @patient.full_name
  end

  def when_i_record_that_they_are_safe_to_vaccinate
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def then_i_see_the_consents_page
    expect(page).to have_content("Check consent responses")
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
