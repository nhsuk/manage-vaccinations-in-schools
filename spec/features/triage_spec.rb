require "rails_helper"

describe "Triage" do
  include EmailExpectations

  scenario "nurse can triage a patient" do
    given_a_campaign_with_a_running_session
    when_i_go_to_the_patient_that_needs_triage
    then_i_see_the_triage_options

    when_i_save_the_triage_without_choosing_an_option
    then_i_see_a_validation_error

    when_i_record_that_they_need_triage
    then_i_see_the_triage_page
    and_needs_triage_emails_are_sent_to_both_parents

    when_i_go_to_the_patient
    and_i_delay_the_vaccination
    then_i_see_the_triage_page
    and_vaccination_wont_happen_emails_are_sent_to_both_parents

    when_i_go_to_the_patient
    then_i_see_the_update_triage_link

    when_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_triage_page
    and_vaccination_will_happen_emails_are_sent_to_both_parents
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
    create(
      :consent_given,
      :health_question_notes,
      :from_granddad,
      patient: @patient,
      campaign: @campaign
    )
    @patient.reload # Make sure both consents are accessible
  end

  def when_i_go_to_the_patient_that_needs_triage
    sign_in @team.users.first
    visit session_triage_tab_path(@session, tab: "needed")
    click_link @patient.full_name
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name, match: :first
  end

  def when_i_record_that_they_need_triage
    choose "No, keep in triage"
    click_button "Save triage"
  end

  def when_i_record_that_they_are_safe_to_vaccinate
    click_link "Update triage"
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def and_i_delay_the_vaccination
    choose "No, delay vaccination to a later date"
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

  def then_i_see_the_update_triage_link
    expect(page).to have_link "Update triage"
  end

  def and_needs_triage_emails_are_sent_to_both_parents
    expect_email_to @patient.consents.first.parent.email,
                    EMAILS[:parental_consent_confirmation_needs_triage]
    expect_email_to @patient.consents.second.parent.email,
                    EMAILS[:parental_consent_confirmation_needs_triage],
                    :second
    ActionMailer::Base.deliveries.clear
  end

  def and_vaccination_wont_happen_emails_are_sent_to_both_parents
    expect_email_to @patient.consents.first.parent.email,
                    EMAILS[:triage_vaccination_wont_happen]
    expect_email_to @patient.consents.second.parent.email,
                    EMAILS[:triage_vaccination_wont_happen],
                    :second
    ActionMailer::Base.deliveries.clear
  end

  def and_vaccination_will_happen_emails_are_sent_to_both_parents
    expect_email_to @patient.consents.first.parent.email,
                    EMAILS[:triage_vaccination_will_happen]
    expect_email_to @patient.consents.second.parent.email,
                    EMAILS[:triage_vaccination_will_happen],
                    :second
    ActionMailer::Base.deliveries.clear
  end
end
