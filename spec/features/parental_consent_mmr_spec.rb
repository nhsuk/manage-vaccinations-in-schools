# frozen_string_literal: true

describe "Parental consent" do
  before { given_an_mmr_programme_is_underway }

  scenario "MMR - any vaccine" do
    when_i_go_to_the_consent_form
    then_i_see_the_consent_form

    when_i_give_consent(without_gelatine: false)
    then_i_see_the_first_health_question

    when_i_answer_no_to_all_health_questions
    then_i_see_the_check_and_confirm_page

    when_i_submit_the_consent_form
    then_i_see_the_confirmation_page
  end

  scenario "MMR - without gelatine" do
    when_i_go_to_the_consent_form
    then_i_see_the_consent_form

    when_i_give_consent(without_gelatine: true)
    then_i_see_the_first_health_question

    when_i_answer_no_to_all_health_questions
    then_i_see_the_check_and_confirm_page

    when_i_submit_the_consent_form
    then_i_see_the_confirmation_page
  end

  def given_an_mmr_programme_is_underway
    @programme = create(:programme, :mmr)
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    location = create(:school, name: "Pilot School", programmes: [@programme])
    @session = create(:session, :scheduled, programmes: [@programme], location:)
    @child = create(:patient, session: @session)
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def then_i_see_the_consent_form
    expect(page).to have_content("Give or refuse consent for vaccinations")
  end

  def when_i_give_consent(without_gelatine:)
    click_button "Start now"

    # What is your child's name?
    fill_in "First name", with: @child.given_name
    fill_in "Last name", with: @child.family_name
    choose "No"
    click_button "Continue"

    # What is your child's date of birth?
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_button "Continue"

    # Confirm your child's school
    choose "Yes"
    click_button "Continue"

    # About you
    fill_in "Full name", with: "Jane #{@child.family_name}"
    choose "Mum"
    fill_in "Email address", with: "jane@example.com"
    click_button "Continue"

    # Do you agree?
    choose "Yes, I agree"
    click_button "Continue"

    # Without gelatine
    if without_gelatine
      choose "I want my child to have the vaccine that does not contain gelatine"
    else
      choose "My child can have either type of vaccine"
    end
    click_button "Continue"

    # Home address
    fill_in "Address line 1", with: "1 High Street"
    fill_in "Town or city", with: "London"
    fill_in "Postcode", with: "SW1 1AA"
    click_button "Continue"
  end

  def then_i_see_the_first_health_question
    expect(page).to have_content(
      "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
    )
  end

  def when_i_answer_no_to_all_health_questions
    3.times do
      choose "No"
      click_button "Continue"
    end
  end

  def then_i_see_the_check_and_confirm_page
    expect(page).to have_content("Check and confirm")
  end

  def when_i_submit_the_consent_form
    click_on "Confirm"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("is due to get the MMR vaccination at school")
  end
end
