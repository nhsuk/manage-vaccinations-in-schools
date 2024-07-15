# frozen_string_literal: true

require "rails_helper"

describe "Parental consent" do
  include EmailExpectations

  before { Flipper.enable(:parent_contact_method) }

  scenario "Consent form exactly matches the cohort" do
    given_an_hpv_campaign_is_underway
    when_a_nurse_checks_consent_responses
    then_there_should_be_no_consent_for_my_child

    when_i_go_to_the_consent_form
    when_i_fill_in_my_childs_name_and_birthday

    when_i_do_not_confirm_they_attend_the_pilot_school
    then_i_see_a_page_telling_me_i_cannot_continue

    when_i_give_consent
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers

    when_i_submit_the_consent_form
    then_i_get_a_confirmation_email_and_scheduled_survey_email

    when_the_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent
    and_they_see_the_full_consent_form

    when_they_check_triage
    then_the_patient_should_be_ready_to_vaccinate
  end

  def given_an_hpv_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team: @team)
    location = create(:location, name: "Pilot School")
    @session =
      create(:session, :in_future, campaign:, location:, patients_in_session: 1)
    @child = @session.patients.first
  end

  def when_a_nurse_checks_consent_responses
    sign_in @team.users.first
    visit "/dashboard"

    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_there_should_be_no_consent_for_my_child
    expect(page).to have_content("No consent")

    click_on "No consent"
    expect(page).to have_content(@child.full_name)
  end

  def when_i_go_to_the_consent_form
    visit start_session_parent_interface_consent_forms_path(@session)
  end

  def when_i_give_consent
    choose "Yes, they go to this school"
    click_on "Continue"

    expect(page).to have_content("About you")
    fill_in "Your name", with: "Jane #{@child.last_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"
    click_on "Continue"

    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"
    click_on "Continue"

    expect(page).to have_content("Do you agree")
    choose "Yes, I agree"
    click_on "Continue"

    expect(page).to have_content("Is your child registered with a GP?")
    choose "Yes, they are registered with a GP"
    fill_in "Name of GP surgery", with: "GP Surgery"
    click_on "Continue"

    expect(page).to have_content("Home address")
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "TE1 1ST"
    click_on "Continue"
  end

  def when_i_fill_in_my_childs_name_and_birthday
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.first_name
    fill_in "Last name", with: @child.last_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"
  end

  def when_i_do_not_confirm_they_attend_the_pilot_school
    choose "No, they go to a different school"
    click_on "Continue"
  end

  def then_i_see_a_page_telling_me_i_cannot_continue
    expect(page).to have_content("You cannot give or refuse consent")

    click_link "Back"
  end

  def and_i_answer_no_to_all_the_medical_questions
    until page.has_content?("Check your answers and confirm")
      choose "No"
      click_on "Continue"
    end
  end

  def then_i_can_check_my_answers
    expect(page).to have_content("Check your answers and confirm")
    expect(page).to have_content("Child’s name#{@child.full_name}")
  end

  def when_i_submit_the_consent_form
    click_on "Confirm"
  end

  def then_i_get_a_confirmation_email_and_scheduled_survey_email
    expect(page).to have_content(
      "#{@child.full_name} will get their HPV vaccination at school"
    )

    perform_enqueued_jobs

    mails = ActionMailer::Base.deliveries
    expect(mails.count).to eq(2)

    expect(mails.first).to be_sent_with_govuk_notify.using_template(
      EMAILS[:parental_consent_confirmation]
    ).to("jane@example.com")

    expect(mails.second).to be_sent_with_govuk_notify.using_template(
      EMAILS[:parental_consent_give_feedback]
    ).to("jane@example.com")
  end

  def when_the_nurse_checks_the_consent_responses
    sign_in @team.users.first
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content("Given")
    click_on "Given"
    expect(page).to have_content(@child.full_name)
  end

  def and_they_see_the_full_consent_form
    click_on @child.full_name
    click_on "Jane #{@child.last_name}"

    expect(page).to have_content(
      "Consent response from Jane #{@child.last_name}"
    )
    expect(page).to have_content(["GP surgery", "GP Surgery"].join)
    expect(page).to have_content(
      [
        "Home address",
        "1 Test Street",
        "2nd Floor",
        "Testville",
        "TE1 1ST"
      ].join
    )
    expect(page).to have_content(["School", "Pilot School"].join)

    click_on "Back to patient page"
    click_on "Back to consents page"
  end

  def when_they_check_triage
    click_link "HPV session at Pilot School"
    click_on "Triage health questions"
    click_on "No triage needed"
  end

  def then_the_patient_should_be_ready_to_vaccinate
    expect(page).to have_content(@child.full_name)
    click_on @child.full_name
    expect(page).to have_content("#{@child.full_name} is safe to vaccinate")
  end
end
