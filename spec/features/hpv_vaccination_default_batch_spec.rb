# frozen_string_literal: true

require "rails_helper"

describe "HPV Vaccination" do
  scenario "Default batch" do
    given_i_am_signed_in
    when_i_vaccinate_a_patient
    then_i_see_the_default_batch_banner_with_batch_1

    when_i_click_the_change_batch_link
    then_i_see_the_change_batch_page

    when_i_choose_the_second_batch
    then_i_see_the_default_batch_banner_with_batch_2
  end

  def given_i_am_signed_in
    campaign = create(:example_campaign, :in_progress)
    team = campaign.team
    @batch = campaign.batches.first
    @batch2 = campaign.batches.second
    @session = campaign.sessions.first
    @patient =
      @session
        .patient_sessions
        .find { _1.state == "consent_given_triage_not_needed" }
        .patient

    sign_in team.users.first
  end

  def when_i_vaccinate_a_patient
    visit session_vaccinations_path(@session)
    click_link @patient.full_name

    choose "Yes, they got the HPV vaccine"
    choose "Left arm"
    click_button "Continue"

    choose @batch.name

    # Find the selected radio button element
    selected_radio_button = find(:radio_button, @batch.name, checked: true)

    # Find the "Default to this batch for this session" checkbox immediately below and check it
    checkbox_below =
      selected_radio_button.find(
        :xpath,
        'following::input[@type="checkbox"][1]'
      )
    checkbox_below.check
    click_button "Continue"

    click_button "Confirm"
  end

  def then_i_see_the_default_batch_banner_with_batch_1
    expect(page).to have_content(/You are currently using.*#{@batch.name}/)
  end

  def then_i_see_the_default_batch_banner_with_batch_2
    expect(page).to have_content(/You are currently using.*#{@batch2.name}/)
  end

  def when_i_click_the_change_batch_link
    click_link "Change the default batch"
  end

  def then_i_see_the_change_batch_page
    expect(page).to have_content("Select a default batch for this session")
    expect(page).to have_selector(:label, @batch.name)
    expect(page).to have_selector(:label, @batch2.name)
  end

  def when_i_choose_the_second_batch
    choose @batch2.name
    click_button "Continue"
  end
end
