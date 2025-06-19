# frozen_string_literal: true

describe "Verbal consent recorded by admin" do
  scenario "Given with some freetext health answers" do
    given_i_am_signed_in_as_an_admin

    when_i_record_that_consent_was_given_but_keep_in_triage

    then_an_email_is_sent_to_the_parent_about_triage
    and_the_patient_status_is_needing_triage
  end

  def given_i_am_signed_in_as_an_admin
    programmes = [create(:programme, :hpv)]
    organisation = create(:organisation, :with_one_admin, programmes:)
    @session = create(:session, organisation:, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])

    sign_in organisation.users.first, role: :admin_staff
  end

  def when_i_record_that_consent_was_given_but_keep_in_triage
    visit session_consent_path(@session)
    click_link @patient.full_name
    click_button "Get verbal consent"

    # Who are you trying to get consent from?
    choose @parent.full_name
    click_button "Continue"

    # Details for parent or guardian: leave prepopulated details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".nhsuk-fieldset")[0].choose "Yes"
    find_all(".nhsuk-fieldset")[0].fill_in "Give details",
              with: "moar allergies"
    find_all(".nhsuk-fieldset")[1].choose "No"
    find_all(".nhsuk-fieldset")[2].choose "No"
    find_all(".nhsuk-fieldset")[3].choose "No"
    click_button "Continue"

    expect(page).not_to have_content("Is it safe to vaccinate?")
    expect(page).to have_content("Check and confirm answers")

    # Confirm
    click_button "Confirm"

    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patient_status_is_needing_triage
    click_link @patient.full_name, match: :first
    expect(page).to have_content("Needs triage")
  end

  def then_an_email_is_sent_to_the_parent_about_triage
    expect_email_to(@parent.email, :consent_confirmation_triage)
  end
end
