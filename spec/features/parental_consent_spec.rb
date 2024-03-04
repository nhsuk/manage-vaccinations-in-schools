require "rails_helper"

RSpec.describe "Parental consent" do
  include SessionCreationSteps

  before { Flipper.enable(:parent_contact_method) }

  scenario "Consent form exactly matches the cohort" do
    given_the_local_sais_team_is_running_an_hpv_vaccination_campaign
    and_they_arrange_a_session_at_my_childs_school_with_my_child_in_the_cohort
    then_they_see_that_no_consent_has_been_given_for_my_child

    when_i_follow_the_link_from_the_email_i_received_to_the_consent_form
    then_i_see_the_consent_form

    when_i_give_consent_for_my_child_to_have_the_vaccination_in_school
    and_i_do_not_indicate_anything_out_of_the_ordinary_with_my_childs_health
    and_i_submit_the_consent_form
    then_i_get_a_confirmation_email_and_scheduled_survey_email

    when_the_sais_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent
    and_they_do_not_need_triage
    and_they_are_ready_to_vaccinate
  end

  scenario "Child isn't at the school" do
    given_the_local_sais_team_is_running_an_hpv_vaccination_campaign
    and_they_arrange_a_session_at_my_childs_school_with_my_child_in_the_cohort
    then_they_see_that_no_consent_has_been_given_for_my_child

    when_i_follow_the_link_from_the_email_i_received_to_the_consent_form
    then_i_see_the_consent_form

    when_i_fill_in_my_childs_name_matching_the_sais_record
    and_i_fill_in_my_childs_date_of_birth_matching_the_sais_record

    when_i_do_not_confirm_they_attend_the_pilot_school
    then_i_see_a_page_telling_me_i_cannot_continue
  end

  def given_the_local_sais_team_is_running_an_hpv_vaccination_campaign
    @team =
      create(
        :team,
        :with_one_nurse,
        nurse_email: "nurse.testy@example.com",
        nurse_password: "nurse.testy@example.com"
      )
    create(:campaign, :hpv, team: @team)
  end

  def and_they_arrange_a_session_at_my_childs_school_with_my_child_in_the_cohort
    @school =
      create(
        :location,
        name: "Pilot School",
        team: @team,
        registration_open: true,
        permission_to_observe_required: true
      )
    @child = create(:patient, location: @school)

    sign_in_as_nurse_testy
    start_new_session(
      school_name: @school.name,
      session_date: 1.week.from_now,
      time_of_day: "Morning"
    )
    select_cohort(names: [@child.full_name])
    schedule_key_dates(send_consent_on_date: Time.zone.today)
    confirm_session_details(
      number_of_children: 1,
      send_consent_on_date: Time.zone.today,
      session_date: 1.week.from_now
    )
  end

  def sign_in_as_nurse_testy
    if page.current_url.present? && page.has_content?("Sign out")
      click_on "Sign out"
    end

    visit "/dashboard"
    fill_in "Email address", with: "nurse.testy@example.com"
    fill_in "Password", with: "nurse.testy@example.com"
    click_button "Sign in"
    expect(page).to have_content("Signed in successfully.")
  end

  def then_they_see_that_no_consent_has_been_given_for_my_child
    sign_in_as_nurse_testy

    find("a", text: "School sessions", match: :first).click
    expect(page).to have_content("School sessions")

    click_on @school.name
    click_on "Check consent responses"

    expect(page).to have_content("No response (1)")
    click_on "No response (1)"
    expect(page).to have_content(@child.full_name)
  end

  def when_i_follow_the_link_from_the_email_i_received_to_the_consent_form
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.count).to eq(1)

    invitation_to_give_consent = ActionMailer::Base.deliveries.last
    expect(invitation_to_give_consent.to).to eq([@child.parent_email])

    consent_url =
      invitation_to_give_consent.header["personalisation"].unparsed_value[
        :consent_link
      ]
    ActionMailer::Base.deliveries.clear

    visit URI.parse(consent_url).path
  end

  def then_i_see_the_consent_form
    expect(page).to have_content(
      "Give or refuse consent for an HPV vaccination"
    )
  end

  def when_i_give_consent_for_my_child_to_have_the_vaccination_in_school
    when_i_fill_in_my_childs_name_matching_the_sais_record
    and_i_fill_in_my_childs_date_of_birth_matching_the_sais_record
    and_i_confirm_they_attend_the_pilot_school
    and_i_fill_in_details_about_me
    and_i_provide_my_phone_contact_preferences
    and_i_give_consent_to_the_vaccination
    and_i_provide_my_childs_gp_details
    and_i_provide_the_home_address
  end

  def and_i_do_not_indicate_anything_out_of_the_ordinary_with_my_childs_health
    and_i_answer_no_to_all_the_medical_questions
    then_i_check_my_answers
  end

  def when_i_fill_in_my_childs_name_matching_the_sais_record
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.first_name
    fill_in "Last name", with: @child.last_name

    # Do they use a different name in school?
    choose "No"

    click_on "Continue"
  end

  def and_i_fill_in_my_childs_date_of_birth_matching_the_sais_record
    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"
  end

  def and_i_confirm_they_attend_the_pilot_school
    expect(page).to have_content("Confirm your child’s school")
    expect(page).to have_content("Pilot School")

    choose "Yes, they go to this school"
    click_on "Continue"
  end

  def when_i_do_not_confirm_they_attend_the_pilot_school
    expect(page).to have_content("Confirm your child’s school")
    expect(page).to have_content("Pilot School")

    choose "No, they go to a different school"
    click_on "Continue"
  end

  def then_i_see_a_page_telling_me_i_cannot_continue
    expect(page).to have_content(
      "You cannot give or refuse consent through this service"
    )
  end

  def and_i_fill_in_details_about_me
    expect(page).to have_content("About you")
    fill_in "Your name", with: "Jane #{@child.last_name}"

    # Your relationship to the child
    choose "Mum"

    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"

    click_on "Continue"
  end

  def and_i_provide_my_phone_contact_preferences
    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"

    click_on "Continue"
  end

  def and_i_give_consent_to_the_vaccination
    expect(page).to have_content(
      "Do you agree to them having the HPV vaccination?"
    )
    choose "Yes, I agree"
    click_on "Continue"
  end

  def and_i_provide_my_childs_gp_details
    expect(page).to have_content("Is your child registered with a GP?")
    choose "Yes, they are registered with a GP"
    fill_in "Name of GP surgery", with: "GP Surgery"
    click_on "Continue"
  end

  def and_i_provide_the_home_address
    expect(page).to have_content("Home address")
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "TE1 1ST"
    click_on "Continue"
  end

  def and_i_answer_no_to_all_the_medical_questions
    until page.has_content?("Check your answers and confirm")
      choose "No"
      click_on "Continue"
    end
  end

  def then_i_check_my_answers
    expect(page).to have_content("Check your answers and confirm")

    expect(page).to have_content("Child’s name#{@child.full_name}")
  end

  def and_i_submit_the_consent_form
    click_on "Confirm"
    expect(page).to have_content(
      "#{@child.full_name} will get their HPV vaccination at school"
    )
  end

  def then_i_get_a_confirmation_email_and_scheduled_survey_email
    expect(enqueued_jobs.first["scheduled_at"]).to be_nil
    expect(
      Time.zone.parse(enqueued_jobs.second["scheduled_at"]).to_i
    ).to be_within(1.second).of(1.hour.from_now.to_i)

    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.count).to eq(2)
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to eq(
      ["jane@example.com"] * 2
    )
  end

  def when_the_sais_nurse_checks_the_consent_responses
    sign_in_as_nurse_testy
    find("a", text: "School sessions", match: :first).click
    click_on @school.name
    click_on "Check consent responses"
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content("Given (1)")
    click_on "Given (1)"
    expect(page).to have_content(@child.full_name)
  end

  def and_they_do_not_need_triage
    find("a", text: "HPV session at #{@school.name}", match: :first).click
    click_on "Triage health questions"
    click_on "No triage needed (1)"
    expect(page).to have_content(@child.full_name)
  end

  def and_they_are_ready_to_vaccinate
    click_on @child.full_name
    expect(page).to have_content("#{@child.full_name} is ready to vaccinate")
  end
end
