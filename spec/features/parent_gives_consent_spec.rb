require "rails_helper"

module SessionCreationSteps
  def start_new_session(school_name:, session_date:, time_of_day:)
    find("a", text: "School sessions", match: :first).click
    click_on "Add a new session"

    expect(page).to have_content("Which school is it at?")
    choose school_name
    click_on "Continue"

    expect(page).to have_content("When is the session?")
    fill_in "Day", with: session_date.day
    fill_in "Month", with: session_date.month
    fill_in "Year", with: session_date.year
    choose time_of_day
    click_on "Continue"
  end

  def select_cohort(names:)
    expect(page).to have_content("Choose cohort for this session")
    all("input[type=checkbox]").each do |checkbox| # uncheck all the children
      checkbox.set(false)
    end

    names.each do |name|
      within page.find("tr", text: name) do
        find("input[type=checkbox]").check
      end
    end

    click_on "Continue"
  end

  def schedule_key_dates(send_consent_on_date:)
    expect(page).to have_content("What’s the timeline for consent requests?")
    within("fieldset", text: "Consent requests") do
      fill_in "Day", with: send_consent_on_date.day
      fill_in "Month", with: send_consent_on_date.month
      fill_in "Year", with: send_consent_on_date.year
    end

    within("fieldset", text: "Reminders") do
      choose "2 days after the first consent request"
    end

    within("fieldset", text: "Deadline for responses") do
      choose "Allow responses until the day of the session"
    end

    click_on "Continue"
  end

  def confirm_session_details(
    number_of_children:,
    send_consent_on_date:,
    session_date:
  )
    expect(page).to have_content("Check and confirm details")
    expect(page).to have_content("Pilot School")
    expect(page).to have_content("Morning")
    expect(page).to have_content("#{number_of_children} child") # could be singular or plural

    expect(page).to have_content(
      "Consent requestsSend on #{send_consent_on_date.strftime("%A, %-d %B %Y")}"
    )
    expect(page).to have_content(
      "RemindersSend on #{(send_consent_on_date + 2.days).strftime("%A, %-d %B %Y")}"
    ) # default
    expect(page).to have_content(
      "Deadline for responsesAllow responses until the day of the session"
    )
    expect(page).to have_content(
      "Date#{session_date.strftime("%A, %-d %B %Y")}"
    )

    click_on "Confirm"
  end
end

RSpec.feature "Parent gives consent", type: :feature do
  include SessionCreationSteps

  before do
    team = create(:team, name: "School Nurses")
    @campaign = create(:campaign, :hpv, team:)
    create(
      :user,
      email: "nurse.testy@example.com",
      password: "nurse.testy@example.com",
      teams: [team]
    )

    @school =
      create(
        :location,
        name: "Pilot School",
        team:,
        registration_open: true,
        permission_to_observe_required: true
      )
  end

  scenario "Parent gives consent, their consent form exactly matches the cohort" do
    given_the_sais_team_has_my_childs_record_in_their_cohort
    and_the_sais_team_has_organised_a_session_at_my_childs_school
    then_they_see_that_no_consent_has_been_given_for_my_child

    perform_enqueued_jobs

    when_i_follow_the_link_from_the_email_i_received_to_the_consent_form
    then_i_see_the_consent_form

    when_i_fill_in_my_childs_name_matching_the_sais_record
    and_i_fill_in_my_childs_date_of_birth_matching_the_sais_record
    and_i_confirm_they_attend_the_pilot_school
    and_i_fill_in_details_about_me
    and_i_provide_my_phone_contact_preferences
    and_i_give_consent_to_the_vaccination
    and_i_provide_my_childs_gp_details
    and_i_provide_the_home_address
    and_i_answer_no_to_all_the_medical_questions

    then_i_see_a_confirmation_page
    and_i_submit_the_consent_form
    and_i_get_a_confirmation_email

    perform_enqueued_jobs

    when_the_sais_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent
    and_they_do_not_need_triage
    and_they_are_ready_to_vaccinate
  end

  def given_the_sais_team_has_my_childs_record_in_their_cohort
    @child = create(:patient, location: @school)
  end

  def and_the_sais_team_has_organised_a_session_at_my_childs_school
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
    expect(ActionMailer::Base.deliveries.count).to eq(1)

    invitation_to_give_consent = ActionMailer::Base.deliveries.last
    # this is awful but I can't figure out how to get the link out of the Notify email
    consent_url =
      invitation_to_give_consent.to_s.match(/consent_link=>"([^"]+)"/)[1]
    visit URI.parse(consent_url).path
  end

  def then_i_see_the_consent_form
    expect(page).to have_content(
      "Give or refuse consent for an HPV vaccination"
    )
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

  def then_i_see_a_confirmation_page
    expect(page).to have_content("Check your answers and confirm")

    expect(page).to have_content("Child’s name#{@child.full_name}")
  end

  def and_i_submit_the_consent_form
    click_on "Confirm"
    expect(page).to have_content(
      "#{@child.full_name} will get their HPV vaccination at school"
    )
  end

  def and_i_get_a_confirmation_email
    # not sure how to do this yet
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
