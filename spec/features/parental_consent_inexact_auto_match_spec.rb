# frozen_string_literal: true

describe "Parental consent given with an inexact automatic match" do
  scenario "Consent form matches the cohort on three of four fields" do
    stub_pds_search_to_return_no_patients

    given_an_hpv_programme_is_underway
    and_the_child_is_present_in_the_cohort

    when_a_parent_gives_consent_with_three_of_four_fields_matching_the_cohort
    and_the_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    location = create(:school, name: "Pilot School")
    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programme: @programme,
        location:
      )
  end

  def and_the_child_is_present_in_the_cohort
    @child =
      create(
        :patient,
        session: @session,
        given_name: "Joanna",
        family_name: "Smith",
        date_of_birth: Date.new(2011, 1, 1),
        address_postcode: "TE1 1ST"
      )
  end

  def when_a_parent_gives_consent_with_three_of_four_fields_matching_the_cohort
    visit start_parent_interface_consent_forms_path(@session, @programme)
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: "Joanna "
    fill_in "Last name", with: "Smith"
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: "1"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2011"
    click_on "Continue"

    choose "Yes, they go to this school"
    click_on "Continue"

    expect(page).to have_content("About you")
    fill_in "Your name", with: "Jane #{@child.family_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    click_on "Continue"

    expect(page).to have_content("Do you agree")
    choose "Yes, I agree"
    click_on "Continue"

    expect(page).to have_content("Home address") # they've moved recently
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "SW1A 1AA"
    click_on "Continue"

    until page.has_content?("Check your answers and confirm")
      choose "No"
      click_on "Continue"
    end

    expect(page).to have_content("Child’s nameSMITH, Joanna")
    click_on "Confirm"

    expect(page).to have_content(
      "SMITH, Joanna will get their HPV vaccination at school"
    )
  end

  def and_the_nurse_checks_the_consent_responses
    perform_enqueued_jobs

    sign_in @organisation.users.first
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content("Consent given")
    click_on "Consent given"
    expect(page).to have_content(@child.full_name)
  end
end
