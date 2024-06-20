require "rails_helper"

describe "HPV Vaccination" do
  scenario "Default batch" do
    given_i_am_signed_in
    when_i_vaccinate_a_patient
    then_i_see_the_default_batch_banner
  end

  def given_i_am_signed_in
    campaign = create(:example_campaign, :in_progress)
    team = campaign.team
    @batch = campaign.batches.first
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
    check "Default to this batch for today"
    click_button "Continue"

    click_button "Confirm"
  end

  def then_i_see_the_default_batch_banner
    expect(page).to have_content("You are currently using")
  end
end
