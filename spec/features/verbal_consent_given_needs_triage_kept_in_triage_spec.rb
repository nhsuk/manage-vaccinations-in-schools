require "rails_helper"

RSpec.describe "Verbal consent" do
  scenario "parent gives consent, triage required, kept in triage" do
    given_i_am_signed_in
    when_i_get_verbal_consent_for_a_patient
    then_the_consent_form_is_prefilled

    when_i_record_that_consent_was_given
    then_i_see_the_consent_responses_page

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_needs_triage
    and_the_kept_in_triage_email_is_sent_to_the_parent
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

  def when_i_record_that_consent_was_given
    # Who are you trying to get consent from?
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".edit_consent .nhsuk-fieldset")[0].choose "Yes"
    find_all(".edit_consent .nhsuk-fieldset")[0].fill_in "Give details",
              with: "moar allergies"
    find_all(".edit_consent .nhsuk-fieldset")[1].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "No"
    choose "No, keep in triage"
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

  def then_i_see_that_the_status_is_needs_triage
    expect(page).to have_content("Needs triage")
  end

  def and_the_kept_in_triage_email_is_sent_to_the_parent
    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to eq [@patient.parent_email]
    expect(
      email[:template_id].value
    ).to eq "604ee667-c996-471e-b986-79ab98d0767c"
  end
end
