require "rails_helper"

RSpec.describe "Pilot journey" do
  before { Timecop.freeze(Time.zone.local(2024, 2, 1)) }
  after { Timecop.return }

  before { Flipper.enable :registration_open }

  scenario "Parent registration, cohorting, session creation, verbal consent, \
vaccination" do
    # Parent registration
    given_an_hpv_campaign_is_underway
    when_i_register_for_the_pilot_as_a_parent
    then_i_see_that_i_have_registered

    # Cohorting
    given_i_am_a_nurse_signed_into_the_service
    when_i_close_the_registration_for_the_pilot
    then_i_see_that_registrations_are_closed

    when_i_download_the_list_of_parents_interested_in_the_pilot
    then_i_see_the_newly_registered_parent_in_the_csv

    when_i_edit_and_upload_the_cohort_list
    then_i_see_that_the_cohort_has_been_uploaded

    # Session creation
    when_i_start_creating_a_new_session_by_choosing_school_and_time
    and_select_the_children_for_the_cohort
    and_enter_timelines_and_confirm_the_session_details
    then_i_see_the_session_page

    when_i_look_at_children_that_need_consent_responses
    then_i_see_the_children_from_the_cohort

    when_i_click_on_the_child_we_registered
    then_i_see_the_childs_details_including_the_updated_nhs_number

    # Verbal consent
    given_the_day_of_the_session_comes
    when_i_register_verbal_consent_and_triage
    then_i_should_see_that_the_patient_is_ready_for_vaccination

    # Vaccination
    when_i_record_the_successful_vaccination
    then_i_see_that_the_child_is_vaccinated
  end

  def given_an_hpv_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    @campaign = create(:campaign, :hpv, team: @team)
    @school = create(:location, name: "Pilot School", team: @team)
  end

  def when_i_register_for_the_pilot_as_a_parent
    visit "/schools/#{@school.id}/registration/new"
    expect(page).to have_content("Pilot School")

    fill_in "Your name", with: "Big Daddy Tests"
    choose "Dad"
    fill_in "Email address", with: "daddy.tests@example.com"
    fill_in "Phone number", with: "07123456789"
    fill_in "First name", with: "Bobby"
    fill_in "Last name", with: "Tables"
    choose "Yes"
    fill_in "Preferred name", with: "Drop Table"
    fill_in "Day", with: "01"
    fill_in "Month", with: "01"
    fill_in "Year", with: "2020"
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "TE1 1ST"
    fill_in "NHS number", with: "999 888 7777"
    check "I agree to take part in the pilot"
    check "I agree to share my contact details"
    check "I confirm I’ve responded to the school"
    check "I agree to my child’s vaccination session being observed"

    click_on "Register your interest"
  end

  def then_i_see_that_i_have_registered
    expect(page).to have_content("Thank you for registering your interest")
  end

  def given_i_am_a_nurse_signed_into_the_service
    sign_in @team.users.first
    visit "/dashboard"
  end

  def when_i_close_the_registration_for_the_pilot
    visit "/pilot"
    click_on "See who’s interested in the pilot"
    click_on "Close pilot to new participants at this school"
    click_on "Yes, close the pilot to new participants"
  end

  def then_i_see_that_registrations_are_closed
    expect(page).to have_content("Pilot is now closed to new participants")
  end

  def when_i_download_the_list_of_parents_interested_in_the_pilot
    click_on "Download data for registered parents (CSV)"

    expect(page.response_headers["Content-Type"]).to eq("text/csv")
    expect(page.response_headers["Content-Disposition"]).to eq(
      "attachment; filename=\"registered_parents.csv\"; filename*=UTF-8''registered_parents.csv"
    )

    @registered_parents_csv = CSV.parse(page.body, headers: true)
  end

  def then_i_see_the_newly_registered_parent_in_the_csv
    expect(@registered_parents_csv[-1].to_h).to include(
      "SCHOOL_ID" => @school.id.to_s,
      "SCHOOL_NAME" => "Pilot School",
      "PARENT_NAME" => "Big Daddy Tests",
      "PARENT_RELATIONSHIP" => "Father",
      "PARENT_EMAIL" => "daddy.tests@example.com",
      "PARENT_PHONE" => "07123456789",
      "CHILD_FIRST_NAME" => "Bobby",
      "CHILD_LAST_NAME" => "Tables",
      "CHILD_COMMON_NAME" => "Drop Table",
      "CHILD_DATE_OF_BIRTH" => "2020-01-01",
      "CHILD_ADDRESS_LINE_1" => "1 Test Street",
      "CHILD_ADDRESS_LINE_2" => "2nd Floor",
      "CHILD_ADDRESS_TOWN" => "Testville",
      "CHILD_ADDRESS_POSTCODE" => "TE1 1ST",
      "CHILD_NHS_NUMBER" => "999 888 7777"
    )
  end

  def when_i_edit_and_upload_the_cohort_list
    @registered_parents_csv[-1]["CHILD_NHS_NUMBER"] = "999 888 6666"

    csv_file = Tempfile.new("cohort_list.csv", Rails.root.join("tmp"))
    csv_file.write(@registered_parents_csv.to_csv)
    csv_file.close

    visit "/pilot"
    click_on "Upload the cohort list"
    attach_file "cohort_list[csv]", csv_file.path
    click_on "Upload the cohort list"
  end

  def then_i_see_that_the_cohort_has_been_uploaded
    expect(page).to have_content("Cohort data uploaded")
  end

  def when_i_start_creating_a_new_session_by_choosing_school_and_time
    click_on "School sessions"
    click_on "Add a new session"

    expect(page).to have_content("Which school is it at?")
    choose "Pilot School"
    click_on "Continue"

    expect(page).to have_content("When is the session?")
    fill_in "Day", with: "1"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"
    choose "Morning"
    click_on "Continue"
  end

  def and_select_the_children_for_the_cohort
    expect(page).to have_content("Choose cohort for this session")
    check "Bobby Tables"
    click_on "Continue"
  end

  def and_enter_timelines_and_confirm_the_session_details
    expect(page).to have_content("What’s the timeline for consent requests?")
    within("fieldset", text: "Consent requests") do
      fill_in "Day", with: "27"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2024"
    end

    within("fieldset", text: "Reminders") do
      choose "2 days after the first consent request"
    end

    within("fieldset", text: "Deadline for responses") do
      choose "Allow responses until the day of the session"
    end

    click_on "Continue"

    expect(page).to have_content("Check and confirm details")
    expect(page).to have_content("Pilot School")
    expect(page).to have_content("Morning")
    expect(page).to have_content("1 child")

    expect(page).to have_content(
      "Consent requestsSend on Tuesday, 27 February 2024"
    )
    expect(page).to have_content("RemindersSend on Thursday, 29 February 2024")
    expect(page).to have_content(
      "Deadline for responsesAllow responses until the day of the session"
    )
    expect(page).to have_content("DateFriday, 1 March 2024")

    click_on "Confirm"
  end

  def then_i_see_the_session_page
    expect(page).to have_content("Pilot School")
  end

  def when_i_look_at_children_that_need_consent_responses
    click_link "Check consent responses"
  end

  def then_i_see_the_children_from_the_cohort
    click_link "No response (1)"
    expect(page).to have_content("Bobby Tables")
  end

  def when_i_click_on_the_child_we_registered
    click_link "Bobby Tables"
  end

  def then_i_see_the_childs_details_including_the_updated_nhs_number
    expect(page).to have_content("NHS Number999 888 6666")
  end

  def given_the_day_of_the_session_comes
    Timecop.travel(2024, 3, 1)
    sign_in @team.users.first
  end

  def when_i_register_verbal_consent_and_triage
    click_button "Get consent"
    click_button "Continue"

    choose "Yes, they agree"
    click_button "Continue"

    find_all(".edit_consent .nhsuk-fieldset")[0].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[1].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "No"
    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    click_button "Confirm"

    click_link "View child record"
  end

  def then_i_should_see_that_the_patient_is_ready_for_vaccination
    expect(page).to have_content "Safe to vaccinate"
  end

  def when_i_record_the_successful_vaccination
    choose "Yes, they got the HPV vaccine"
    choose "Left arm (upper position)"
    click_button "Continue"

    choose @campaign.vaccines.first.batches.first.name
    click_button "Continue"

    click_button "Confirm"
  end

  def then_i_see_that_the_child_is_vaccinated
    expect(page).to have_content "Vaccinated (1)"
  end
end
