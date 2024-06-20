require "rails_helper"

describe "Verbal consent" do
  include EmailExpectations

  scenario "Given, do not vaccinate" do
    given_i_am_signed_in
    when_i_get_verbal_consent_for_a_patient
    then_the_consent_form_is_prefilled

    when_i_record_that_consent_was_given
    then_i_see_the_consent_responses_page

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_do_not_vaccinate
    and_the_will_not_vaccinate_email_is_sent_to_the_parent
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team:)
    @session = create(:session, campaign:, patients_in_session: 1)
    @patient = @session.patients.first

    sign_in team.users.first
  end

  def when_i_get_verbal_consent_for_a_patient
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"
  end

  def then_the_consent_form_is_prefilled
    expect(page).to have_field("Full name", with: @patient.parent.name)
  end

  def when_i_record_that_consent_was_given
    # Who are you trying to get consent from?
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".edit_consent .nhsuk-fieldset")[0].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[1].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "Yes"
    find_all(".edit_consent .nhsuk-fieldset")[2].fill_in "Give details",
              with: "moar reactions"
    click_button "Continue"

    choose "No, do not vaccinate"
    click_button "Continue"

    # Confirm
    click_button "Confirm"
  end

  def then_i_see_the_consent_responses_page
    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name
  end

  def then_i_see_that_the_status_is_do_not_vaccinate
    expect(page).to have_content("Could not vaccinate")
  end

  def and_the_will_not_vaccinate_email_is_sent_to_the_parent
    expect(sent_emails.count).to eq 1

    expect(sent_emails.last).to be_sent_with_govuk_notify.using_template(
      EMAILS[:triage_vaccination_wont_happen]
    ).to(@patient.parent.email)
  end
end
