# frozen_string_literal: true

describe "Verbal consent" do
  include EmailExpectations

  scenario "Given" do
    given_i_am_signed_in

    when_i_record_that_verbal_consent_was_given

    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_the_patients_status_is_safe_to_vaccinate
    and_i_can_see_the_consent_response_details
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    programme = create(:programme, :hpv, team:)
    @session = create(:session, programme:)
    @patient = create(:patient, session: @session)

    sign_in team.users.first
  end

  def when_i_record_that_verbal_consent_was_given
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"

    # Who are you trying to get consent from?
    click_button "Continue"
    expect(page).to have_content(
      "Choose who you are trying to get consent from"
    )

    choose "#{@patient.parents.first.name} (#{@patient.parents.first.relationship_label})"
    click_button "Continue"

    # Details for parent or guardian
    expect(page).to have_content(
      "Details for #{@patient.parents.first.name} (#{@patient.parents.first.relationship_label})"
    )
    # don't change any details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".nhsuk-fieldset")[0].choose "No"
    find_all(".nhsuk-fieldset")[1].choose "No"
    find_all(".nhsuk-fieldset")[2].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    # Confirm
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Response method", "By phone"].join)
    click_button "Confirm"

    # Back on the consent responses page
    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_safe_to_vaccinate
    click_link @patient.full_name
    expect(page).to have_content("Safe to vaccinate")
  end

  def and_i_can_see_the_consent_response_details
    parent = @patient.parents.first
    click_link parent.name

    expect(page).to have_content("Consent response from #{parent.name}")
    expect(page).to have_content(
      ["Response date", Time.zone.today.to_fs(:long)].join
    )
    expect(page).to have_content(["Decision", "Consent given"].join)
    expect(page).to have_content(["Response method", "By phone"].join)

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

    expect(page).to have_content("Answers to health questions")
    expect(page).to have_content(
      "#{parent.relationship_label} responded: No",
      count: 3
    )
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect(sent_emails.count).to eq 1

    expect(sent_emails.last).to be_sent_with_govuk_notify.using_template(
      EMAILS[:parental_consent_confirmation]
    ).to(@patient.parents.first.email)
  end
end
