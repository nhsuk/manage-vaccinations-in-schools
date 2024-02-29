require "rails_helper"

RSpec.describe "Manage consent" do
  scenario "Parent refuses verbal consent" do
    given_i_am_signed_in
    when_i_get_verbal_consent_for_a_patient
    then_the_consent_form_is_prefilled

    when_i_record_the_consent_refusal_and_reason
    then_i_see_the_consent_responses_page

    # TODO: This is a bug in the app, their status should be do not vaccinate
    when_i_go_to_the_patient
    then_i_see_that_the_child_needs_their_refusal_checked
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team:)
    @session = create(:session, campaign:, patients_in_session: 1)
    @patient = @session.patients.first

    sign_in team.users.first
  end

  def when_i_get_verbal_consent_for_a_patient
    visit consents_session_path(@session)
    click_link @patient.full_name
    click_button "Get consent"
  end

  def then_the_consent_form_is_prefilled
    expect(page).to have_field("Full name", with: @patient.parent_name)
  end

  def given_i_call_the_parent_and_they_refuse_consent
  end

  def when_i_record_the_consent_refusal_and_reason
    # Who are you trying to get consent from?
    click_button "Continue"

    # Do they agree?
    choose "No, they do not agree"
    click_button "Continue"

    # Reason
    choose "Medical reasons"
    click_button "Continue"

    # Reason notes
    fill_in "Give details", with: "They have a medical condition"
    click_button "Continue"

    # Confirm
    click_button "Confirm"
  end

  def then_i_see_the_consent_responses_page
    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Record saved for #{@patient.full_name}")
  end

  def when_i_go_to_the_patient
    click_link "View child record"
  end

  def then_i_see_that_the_child_needs_their_refusal_checked
    expect(page).to have_content("Consent refused")
  end
end
