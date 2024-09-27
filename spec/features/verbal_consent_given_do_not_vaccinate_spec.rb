# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Given, do not vaccinate" do
    given_i_am_signed_in

    when_i_record_that_verbal_consent_was_given_but_that_its_not_safe_to_vaccinate

    then_an_email_is_sent_to_the_parent_that_the_vaccination_wont_happen
    and_the_patients_status_is_do_not_vaccinate
  end

  def given_i_am_signed_in
    programme = create(:programme, :hpv)
    team = create(:team, :with_one_nurse, programmes: [programme])
    @session = create(:session, team:, programme:)
    @patient = create(:patient, session: @session)

    sign_in team.users.first
  end

  def when_i_record_that_verbal_consent_was_given_but_that_its_not_safe_to_vaccinate
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
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".nhsuk-fieldset")[0].choose "No"
    find_all(".nhsuk-fieldset")[1].choose "No"
    find_all(".nhsuk-fieldset")[2].choose "Yes"
    find_all(".nhsuk-fieldset")[2].fill_in "Give details",
              with: "moar reactions"
    click_button "Continue"

    choose "No, do not vaccinate"
    click_button "Continue"

    # Confirm
    click_button "Confirm"

    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_do_not_vaccinate
    click_link @patient.full_name
    expect(page).to have_content("Could not vaccinate")
  end

  def then_an_email_is_sent_to_the_parent_that_the_vaccination_wont_happen
    expect_email_to(
      @patient.parents.first.email,
      :triage_vaccination_wont_happen
    )
  end
end
