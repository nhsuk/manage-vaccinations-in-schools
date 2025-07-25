# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Given, with health notes but safe to vaccinate" do
    given_i_am_signed_in

    when_i_record_that_consent_was_given_with_some_health_notes_that_dont_contraindicate

    then_an_email_is_sent_to_the_parent_that_vaccination_will_happen
    and_the_patients_status_is_safe_to_vaccinate
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    organisation = create(:organisation, :with_one_nurse, programmes:)

    @session = create(:session, organisation:, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])

    sign_in organisation.users.first
  end

  def when_i_record_that_consent_was_given_with_some_health_notes_that_dont_contraindicate
    visit session_consent_path(@session)
    click_link @patient.full_name
    click_button "Record a new consent response"

    # Who are you trying to get consent from?
    choose @parent.full_name
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
    find_all(".nhsuk-fieldset")[3].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    # Confirm
    click_button "Confirm"

    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_safe_to_vaccinate
    click_link @patient.full_name, match: :first
    expect(page).to have_content("Safe to vaccinate")
  end

  def then_an_email_is_sent_to_the_parent_that_vaccination_will_happen
    expect_email_to(@parent.email, :triage_vaccination_will_happen)
  end
end
