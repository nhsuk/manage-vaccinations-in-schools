# frozen_string_literal: true

describe "Parental consent" do
  scenario "Doubles - consent given for both programmes" do
    stub_pds_search_to_return_no_patients

    given_a_menacwy_programme_is_underway
    when_i_go_to_the_consent_form
    then_i_see_the_consent_form

    when_i_fill_in_my_details
    then_i_see_the_consent_page

    when_i_give_consent_to_both_programmes
    and_i_fill_in_my_address
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers
  end

  scenario "Doubles - consent given for one programme" do
    stub_pds_search_to_return_no_patients

    given_a_menacwy_programme_is_underway
    when_i_go_to_the_consent_form
    then_i_see_the_consent_form

    when_i_fill_in_my_details
    then_i_see_the_consent_page

    when_i_give_consent_to_one_programme
    and_i_fill_in_my_address
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers
  end

  def given_a_menacwy_programme_is_underway
    @programme1 = create(:programme, :menacwy)
    @programme2 = create(:programme, :td_ipv)
    @organisation =
      create(
        :organisation,
        :with_one_nurse,
        programmes: [@programme1, @programme2]
      )
    location = create(:school, name: "Pilot School")
    @session =
      create(
        :session,
        :scheduled,
        programmes: [@programme1, @programme2],
        location:
      )
    @child = create(:patient, session: @session)
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme1)
  end

  def then_i_see_the_consent_form
    expect(page).to have_heading("Give or refuse consent for vaccinations")
    expect(page).to have_heading("MenACWY")
    expect(page).to have_heading("Td/IPV")
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

  def when_i_give_consent_to_both_programmes
    choose "Yes, I agree"
    click_on "Continue"
  end

  def and_i_fill_in_my_address
    expect(page).to have_content("Home address")
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "TE1 1ST"
    click_on "Continue"
  end

  def and_i_answer_no_to_all_the_medical_questions
    until page.has_content?("Check and confirm")
      choose "No"
      click_on "Continue"
    end
  end

  def then_i_can_check_my_answers
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("Child’s name#{@child.full_name}")
  end

  def then_i_see_the_consent_page
    expect(page).to have_heading("Do you agree")
  end

  def when_i_give_consent_to_one_programme
    expect(page).to have_field("MenACWY", type: "radio")
    expect(page).to have_field("Td/IPV", type: "radio")
    choose "I agree to them having one of the vaccinations"
    choose "MenACWY"
    click_on "Continue"
  end
end
