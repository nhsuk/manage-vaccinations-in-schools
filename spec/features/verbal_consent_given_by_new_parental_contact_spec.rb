# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Given by a parental contact not on the system" do
    given_i_am_signed_in

    when_i_start_recording_consent_from_a_new_parental_contact
    and_i_record_that_verbal_consent_was_given

    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_i_can_see_the_parents_details_on_the_consent_response
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    programme = create(:programme, :hpv, team:)
    @session = create(:session, programme:)
    @patient = create(:patient, session: @session)

    sign_in team.users.first
  end

  def when_i_start_recording_consent_from_a_new_parental_contact
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"

    # Who are you trying to get consent from?
    choose "Add a new parental contact"
    click_button "Continue"

    # Details for parent or guardian
    fill_in "Full name", with: "Jane Smith"
    choose "Mum"
    fill_in "Email address", with: "jsmith@example.com"
    fill_in "Phone number", with: "07987654321"
    check "Get updates by text"
    click_button "Continue"
  end

  def and_i_record_that_verbal_consent_was_given
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

  def and_i_can_see_the_parents_details_on_the_consent_response
    click_link @patient.full_name
    click_link "Jane Smith"

    expect(page).to have_content("Consent response from Jane Smith")

    expect(page).to have_content(["Name", "Jane Smith"].join)
    expect(page).to have_content(%w[Relationship Mum].join)
    expect(page).to have_content(["Email address", "jsmith@example.com"].join)
    expect(page).to have_content(["Phone number", "07987654321"].join)
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect_email_to("jsmith@example.com", :parental_consent_confirmation)
  end
end
