# frozen_string_literal: true

describe "Parental consent" do
  scenario "Refused" do
    stub_pds_search_to_return_no_patients

    given_an_hpv_programme_is_underway
    when_i_go_to_the_consent_form
    then_i_see_the_start_page

    when_i_fill_in_my_details
    then_i_see_the_consent_page

    when_i_refuse_consent
    then_i_can_check_my_answers

    when_i_confirm_my_answers
    then_i_see_the_confirmation_page
    and_i_receive_an_email_confirming_that_my_child_wont_be_vaccinated
    and_i_receive_a_text_confirming_that_my_child_wont_be_vaccinated

    when_the_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent_refused
    and_the_session_outcome_is_could_not_vaccinate
    and_the_programme_outcome_is_could_not_vaccinate
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
        programmes: [@programme],
        location:
      )
    @child = create(:patient, session: @session)
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def then_i_see_the_start_page
    expect(page).to have_content("Give or refuse consent for vaccinations")
  end

  def when_i_refuse_consent
    expect(page).to have_content("Do you agree")
    choose "No"
    click_on "Continue"

    expect(page).to have_content(
      "Please tell us why you do not agree to your child having the HPV vaccination"
    )
    choose "Medical reasons"
    click_on "Continue"

    expect(page).to have_content(
      "What medical reasons prevent your child from being vaccinated?"
    )
    fill_in "Give details", with: "They have a weakened immune system"
    click_on "Continue"
  end

  def when_i_fill_in_my_details
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.given_name
    fill_in "Last name", with: @child.family_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"

    expect(page).to have_content("Confirm your child’s school")
    choose "Yes, they go to this school"
    click_on "Continue"

    expect(page).to have_content("About you")
    fill_in "Full name", with: "Jane #{@child.family_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"
    check "Tick this box if you’d like to get updates by text message"
    click_on "Continue"

    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"
    click_on "Continue"
  end

  def then_i_see_the_consent_page
    expect(page).to have_content("Do you agree")
  end

  def then_i_can_check_my_answers
    expect(page).to have_content("Check and confirm")
  end

  def when_i_confirm_my_answers
    click_on "Confirm"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content(
      "You’ve told us that you do not want #{@child.full_name(context: :parents)} to get the HPV vaccination at school"
    )
  end

  def and_i_receive_an_email_confirming_that_my_child_wont_be_vaccinated
    expect_email_to "jane@example.com", :consent_confirmation_refused
  end

  def and_i_receive_a_text_confirming_that_my_child_wont_be_vaccinated
    expect_sms_to "07123 456789", :consent_confirmation_refused
  end

  def when_the_nurse_checks_the_consent_responses
    sign_in @organisation.users.first

    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Consent"
  end

  def then_they_see_that_the_child_has_consent_refused
    expect(page).to have_content("Consent refused")
    choose "Consent refused"
    click_on "Update results"
    expect(page).to have_content(@child.full_name)
  end

  def and_the_session_outcome_is_could_not_vaccinate
    click_on "Session outcomes"
    choose "Refused vaccine"
    click_on "Update results"
    expect(page).to have_content(@child.full_name)
  end

  def and_the_programme_outcome_is_could_not_vaccinate
    click_on "Programmes", match: :first
    click_on "HPV"

    within ".app-secondary-navigation" do
      click_on "Children"
    end

    choose "Could not vaccinate"
    click_on "Update results"

    expect(page).to have_content(@child.full_name)
  end
end
