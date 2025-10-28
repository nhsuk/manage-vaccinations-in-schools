# frozen_string_literal: true

describe "Parental consent" do
  scenario "Flu" do
    given_a_flu_programme_is_underway
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

  scenario "Flu - already has a PSD" do
    stub_pds_search_to_return_no_patients

    given_a_flu_programme_is_underway
    and_the_child_has_a_psd

    when_i_go_to_the_consent_form
    then_i_see_the_consent_form

    when_i_give_consent
    when_i_answer_yes_to_all_health_questions
    then_i_see_the_confirmation_page

    when_i_submit_the_consent_form
    then_the_psd_is_invalidated
  end

  def given_a_flu_programme_is_underway
    @programme = create(:programme, :flu)
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    location = create(:school, name: "Pilot School", programmes: [@programme])
    @session = create(:session, :scheduled, programmes: [@programme], location:)
    @child = create(:patient, session: @session)
  end

  def and_the_child_has_a_psd
    @patient_specific_direction =
      create(
        :patient_specific_direction,
        patient: @child,
        programme: @programme
      )
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def then_i_see_the_consent_form
    expect(page).to have_content("Give or refuse consent for vaccinations")
  end

  def when_i_give_consent
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
    choose "Yes, I agree to them having the nasal spray vaccine"
    click_button "Continue"

    # Injection alternative
    choose "Yes"
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
    9.times do
      choose "No"
      click_button "Continue"
    end
  end

  def when_i_answer_yes_to_all_health_questions
    11.times do
      choose "Yes"

      begin
        fill_in "Give details", with: "Details"
      rescue Capybara::ElementNotFound
        # Some questions don't have a give details text box.
      end

      click_button "Continue"
    end
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm")
  end

  def when_i_change_my_answer_to_the_first_health_question
    click_link "Change your answer to health question 1"

    choose "Yes"
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

  def when_i_submit_the_consent_form
    click_on "Confirm"
    perform_enqueued_jobs
  end

  def then_the_psd_is_invalidated
    expect(@patient_specific_direction.reload).to be_invalidated
  end
end
