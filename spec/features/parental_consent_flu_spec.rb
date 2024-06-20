require "rails_helper"

describe "Parental consent" do
  scenario "Flu campaign" do
    given_a_flu_campaign_is_underway
    when_i_go_to_the_consent_form
    then_i_see_the_consent_form

    when_i_give_consent
    then_i_see_the_first_health_question

    when_i_answer_no_to_all_health_questions
    then_i_see_the_confirmation_page

    when_i_change_my_answer_to_the_first_health_question
    then_i_see_the_follow_up_question

    when_i_answer_the_follow_up_questions
    then_i_see_the_confirmation_page
  end

  def given_a_flu_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :flu, team: @team)
    location = create(:location, name: "Pilot School", team: @team)
    @session =
      create(:session, :in_future, campaign:, location:, patients_in_session: 1)
    @child = @session.patients.first
  end

  def when_i_go_to_the_consent_form
    visit start_session_parent_interface_consent_forms_path(@session)
  end

  def then_i_see_the_consent_form
    expect(page).to have_content("Give or refuse consent for a flu vaccination")
  end

  def when_i_give_consent
    click_button "Start now"

    # What is your child's name?
    fill_in "First name", with: @child.first_name
    fill_in "Last name", with: @child.last_name
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
    fill_in "Your name", with: "Jane #{@child.last_name}"
    choose "Mum"
    fill_in "Email address", with: "jane@example.com"
    click_button "Continue"

    # Do you agree?
    choose "Yes, I agree"
    click_button "Continue"

    # Is your child registered with a GP?
    choose "I don’t know"
    click_button "Continue"

    # Home address
    fill_in "Address line 1", with: "1 High Street"
    fill_in "Town or city", with: "London"
    fill_in "Postcode", with: "SW1 1AA"
    click_button "Continue"
  end

  def then_i_see_the_first_health_question
    expect(page).to have_content("Has your child been diagnosed with asthma?")
  end

  def when_i_answer_no_to_all_health_questions
    8.times do
      choose "No"
      click_button "Continue"
    end
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check your answers")
  end

  def when_i_change_my_answer_to_the_first_health_question
    click_link "Change your answer to health question 1"

    choose "Yes"
    fill_in "Give details", with: "They have asthma"
    click_button "Continue"
  end

  def then_i_see_the_follow_up_question
    expect(page).to have_content(
      "Have they taken oral steroids in the last 2 weeks?"
    )
  end

  def when_i_answer_the_follow_up_questions
    2.times do
      choose "No"
      click_button "Continue"
    end
  end
end
