# frozen_string_literal: true

require "rails_helper"

describe "HPV Vaccination" do
  include EmailExpectations

  scenario "Delayed" do
    given_i_am_signed_in
    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_was_absent
    then_i_see_the_confirmation_page

    when_i_confirm_the_details
    then_i_see_the_record_vaccinations_page
    and_a_success_message

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_delayed
    and_an_email_is_sent_to_the_parent_confirming_the_delay
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse)
    location = create(:location)
    campaign = create(:campaign, :hpv, team: @team)
    @batch = campaign.batches.first
    @session = create(:session, campaign:, location:)
    @patient =
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        session: @session
      ).patient

    sign_in @team.users.first
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_triage_path(@session)
    click_link "No triage needed"
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_was_absent
    choose "No, they did not get it"
    click_button "Continue"

    choose "They were absent from school"
    click_button "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("Child#{@patient.full_name}")
    expect(page).to have_content("OutcomeAbsent from school")
  end

  def when_i_confirm_the_details
    click_button "Confirm"
  end

  def then_i_see_the_record_vaccinations_page
    expect(page).to have_content("Record vaccinations")
  end

  def and_a_success_message
    expect(page).to have_content("Record updated for #{@patient.full_name}")
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name
  end

  def then_i_see_that_the_status_is_delayed
    expect(page).to have_content("Could not vaccinate")
    expect(page).to have_content("#{@team.users.first.full_name} decided that")
  end

  def and_an_email_is_sent_to_the_parent_confirming_the_delay
    expect_email_to(
      @patient.consents.last.parent.email,
      EMAILS[:confirmation_the_hpv_vaccination_didnt_happen]
    )
  end
end
