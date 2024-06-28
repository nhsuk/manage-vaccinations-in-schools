# frozen_string_literal: true

require "rails_helper"

describe "Verbal consent" do
  include EmailExpectations

  scenario "Given" do
    given_i_am_signed_in
    when_i_get_consent_for_a_patient
    then_the_consent_form_is_prefilled

    when_i_record_that_verbal_consent_was_given
    then_i_see_the_consent_responses_page

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_safe_to_vaccinate
    and_i_can_see_the_consent_response
    and_an_email_is_sent_to_the_parent_confirming_their_consent
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team:)
    @session = create(:session, campaign:, patients_in_session: 1)
    @patient = @session.patients.first

    sign_in team.users.first
  end

  def when_i_get_consent_for_a_patient
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"
  end

  def then_the_consent_form_is_prefilled
    expect(page).to have_field("Full name", with: @patient.parent.name)
  end

  def when_i_record_that_verbal_consent_was_given
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
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    # Confirm
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Response method", "By phone"].join)
    click_button "Confirm"
  end

  def then_i_see_the_consent_responses_page
    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name
  end

  def then_i_see_that_the_status_is_safe_to_vaccinate
    expect(page).to have_content("Safe to vaccinate")
  end

  def and_i_can_see_the_consent_response
    click_link @patient.parent.name

    expect(page).to have_content(
      "Consent response from #{@patient.parent.name}"
    )
    expect(page).to have_content(
      ["Response date", Time.zone.today.to_fs(:long)].join
    )
    expect(page).to have_content(["Decision", "Consent given"].join)
    expect(page).to have_content(["Response method", "By phone"].join)

    expect(page).to have_content(["Full name", @patient.full_name].join)
    expect(page).to have_content(
      ["Date of birth", @patient.date_of_birth.to_fs(:long)].join
    )
    expect(page).to have_content(["School", @patient.location.name].join)

    expect(page).to have_content(["Name", @patient.parent.name].join)
    expect(page).to have_content(
      ["Relationship", @patient.parent.relationship_label].join
    )
    expect(page).to have_content(["Email address", @patient.parent.email].join)
    expect(page).to have_content(["Phone number", @patient.parent.phone].join)

    expect(page).to have_content("Answers to health questions")
    expect(page).to have_content(
      "#{@patient.parent.relationship_label} responded: No",
      count: 3
    )
  end

  def and_an_email_is_sent_to_the_parent_confirming_their_consent
    expect(sent_emails.count).to eq 1

    expect(sent_emails.last).to be_sent_with_govuk_notify.using_template(
      EMAILS[:parental_consent_confirmation]
    ).to(@patient.parent.email)
  end
end
