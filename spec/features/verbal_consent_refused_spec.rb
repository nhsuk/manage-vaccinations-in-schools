# frozen_string_literal: true

describe "Verbal consent" do
  include EmailExpectations

  scenario "Refused" do
    given_i_am_signed_in

    when_i_record_the_consent_refusal_and_reason

    then_an_email_is_sent_to_the_parent_confirming_the_refusal
    and_the_patients_status_is_do_not_vaccinate
    and_i_can_see_the_consent_response_details
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    programme = create(:programme, :hpv, team:)
    @session = create(:session, programme:)
    @patient = create(:patient, session: @session)

    sign_in team.users.first
  end

  def when_i_record_the_consent_refusal_and_reason
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"

    # Who are you trying to get consent from?
    choose @patient.parents.first.name
    click_button "Continue"

    # Details for parent or guardian: leave prepopulated details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
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
    expect(page).to have_content(["Decision", "Consent refused"].join)
    expect(page).to have_content(["Name", @patient.parents.first.name].join)
    click_button "Confirm"

    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_do_not_vaccinate
    click_link @patient.full_name
    expect(page).to have_content("Could not vaccinate")
  end

  def and_i_can_see_the_consent_response_details
    parent = @patient.parents.first
    click_link parent.name

    expect(page).to have_content(
      ["Response date", Time.zone.today.to_fs(:long)].join
    )
    expect(page).to have_content(["Decision", "Consent refused"].join)
    expect(page).to have_content(["Response method", "By phone"].join)
    expect(page).to have_content(["Reason for refusal", "Medical reasons"].join)
    expect(page).to have_content(
      ["Refusal details", "They have a medical condition"].join
    )

    expect(page).to have_content(["Full name", @patient.full_name].join)
    expect(page).to have_content(
      ["Date of birth", @patient.date_of_birth.to_fs(:long)].join
    )
    expect(page).to have_content(["School", @patient.school.name].join)

    expect(page).to have_content(["Name", parent.name].join)
    expect(page).to have_content(
      ["Relationship", parent.relationship_label].join
    )
    expect(page).to have_content(["Email address", parent.email].join)
    expect(page).to have_content(["Phone number", parent.phone].join)

    expect(page).not_to have_content("Answers to health questions")
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_refusal
    expect_email_to @patient.parents.first.email,
                    EMAILS[:parental_consent_confirmation_refused]
  end
end
