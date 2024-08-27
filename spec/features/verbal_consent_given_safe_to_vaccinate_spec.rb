# frozen_string_literal: true

describe "Verbal consent" do
  include EmailExpectations

  scenario "Given, with health notes but safe to vaccinate" do
    given_i_am_signed_in

    when_i_record_that_consent_was_given_with_some_health_notes_that_dont_contraindicate

    then_an_email_is_sent_to_the_parent_that_vaccination_will_happen
    and_the_patients_status_is_safe_to_vaccinate
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team:)
    @session = create(:session, campaign:, patients_in_session: 1)
    @patient = @session.patients.first

    sign_in team.users.first
  end

  def when_i_record_that_consent_was_given_with_some_health_notes_that_dont_contraindicate
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"

    # Who are you trying to get consent from?
    choose @patient.parent.name
    click_button "Continue"

    # Details for parent or guardian: leave existing contact details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".nhsuk-fieldset")[0].choose "No"
    find_all(".nhsuk-fieldset")[1].choose "Yes"
    find_all(".nhsuk-fieldset")[1].fill_in "Give details",
              with: "moar medicines"
    find_all(".nhsuk-fieldset")[2].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    # Confirm
    click_button "Confirm"

    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_safe_to_vaccinate
    click_link @patient.full_name
    expect(page).to have_content("Safe to vaccinate")
  end

  def then_an_email_is_sent_to_the_parent_that_vaccination_will_happen
    expect(sent_emails).not_to be_empty

    expect(sent_emails.last).to be_sent_with_govuk_notify.using_template(
      EMAILS[:triage_vaccination_will_happen]
    ).to(@patient.parent.email)
  end
end
