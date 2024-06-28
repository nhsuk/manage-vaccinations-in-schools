# frozen_string_literal: true

require "rails_helper"
require "csv"

describe "Pilot journey" do
  before { Timecop.freeze(Time.zone.local(2024, 2, 1)) }
  after { Timecop.return }

  scenario "Cohorting, session creation, verbal consent, vaccination" do
    # Cohorting
    given_an_hpv_campaign_is_underway
    and_i_am_a_nurse_signed_into_the_service
    when_i_upload_the_cohort_list_containing_one_child
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
    when_i_click_on_the_vaccination_section
    and_i_record_the_successful_vaccination
    then_i_see_that_the_child_is_vaccinated

    # Activity log
    when_i_click_on_the_child_we_registered
    then_i_see_the_activity_log_link

    when_i_go_to_the_activity_log
    then_i_see_the_populated_activity_log
  end

  def given_an_hpv_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    @campaign = create(:campaign, :hpv, team: @team)
    @school = create(:location, name: "Pilot School", team: @team)
  end

  def and_i_am_a_nurse_signed_into_the_service
    sign_in @team.users.first
    visit "/dashboard"
  end

  def when_i_upload_the_cohort_list_containing_one_child
    cohort_data = {
      "SCHOOL_URN" => @school.urn.to_s,
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
      "CHILD_NHS_NUMBER" => "999 888 6666"
    }

    @registered_parents_csv =
      CSV::Table.new([CSV::Row.new(cohort_data.keys, cohort_data.values)])

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
    click_on "Today’s sessions"
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
      "Consent requestsSend on Tuesday 27 February 2024"
    )
    expect(page).to have_content("RemindersSend on Thursday 29 February 2024")
    expect(page).to have_content(
      "Deadline for responsesAllow responses until the day of the session"
    )
    expect(page).to have_content("DateFriday 1 March 2024")

    click_on "Confirm"
  end

  def then_i_see_the_session_page
    expect(page).to have_content("Pilot School")
  end

  def when_i_look_at_children_that_need_consent_responses
    click_link "Check consent responses"
  end

  def then_i_see_the_children_from_the_cohort
    click_link "No consent"
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

    choose "By phone"
    click_button "Continue"

    choose "Yes, they agree"
    click_button "Continue"

    find_all(".edit_consent .nhsuk-fieldset")[0].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[1].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    click_button "Confirm"

    click_link "Bobby Tables"
  end

  def then_i_should_see_that_the_patient_is_ready_for_vaccination
    expect(page).to have_content "Safe to vaccinate"
  end

  def when_i_click_on_the_vaccination_section
    click_link "Back to consents page"
    click_link "HPV session at Pilot School"
    click_link "Record vaccinations"
    click_link "Vaccinate ( 1 )"
  end

  def and_i_record_the_successful_vaccination
    click_link "Bobby Tables"

    choose "Yes, they got the HPV vaccine"
    choose "Left arm (upper position)"
    click_button "Continue"

    choose @campaign.vaccines.first.batches.first.name
    click_button "Continue"

    click_button "Confirm"
  end

  def then_i_see_that_the_child_is_vaccinated
    click_link "Vaccinated ( 1 )"
    expect(page).to have_content "1 child vaccinated"
  end

  def then_i_see_the_activity_log_link
    expect(page).to have_link "Activity log"
  end

  def when_i_go_to_the_activity_log
    click_link "Activity log"
  end

  def then_i_see_the_populated_activity_log
    expect(page).to have_content "Consent given by Big Daddy Tests (Dad)"
  end
end
