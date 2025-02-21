# frozen_string_literal: true

describe "End-to-end journey" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Cohorting, session creation, verbal consent, vaccination" do
    # Cohorting
    given_an_hpv_programme_is_underway
    and_i_am_a_nurse_signed_into_the_service
    when_i_upload_the_cohort_import_containing_one_child
    then_i_see_that_the_cohort_has_been_uploaded

    # Session creation
    when_i_start_creating_a_new_session_by_choosing_school_and_time
    and_confirm_the_session_details
    then_i_see_the_session_page

    when_i_look_at_children_that_need_consent_responses
    then_i_see_the_children_from_the_cohort

    when_i_click_on_the_child_we_registered
    then_i_see_the_childs_details_including_the_updated_nhs_number

    # Verbal consent
    given_the_day_of_the_session_comes
    when_i_register_verbal_consent_and_triage
    then_i_should_see_that_the_patient_is_ready_for_vaccination

    # Attendance
    when_i_click_on_the_register_attendance_section
    and_i_record_the_patient_in_attendance

    # Vaccination
    when_i_click_on_the_vaccination_section
    and_i_record_the_successful_vaccination
    then_i_see_that_the_child_is_vaccinated
    and_i_cant_edit_attendance

    # Activity log
    when_i_click_on_the_child_we_registered
    then_i_see_the_activity_log_link

    when_i_go_to_the_activity_log
    then_i_see_the_populated_activity_log
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    @school =
      create(
        :school,
        :secondary,
        organisation: @organisation,
        name: "Pilot School"
      )
    @batch =
      create(
        :batch,
        expiry: Date.new(2024, 4, 1),
        organisation: @organisation,
        vaccine: @programme.vaccines.first
      )
    create(
      :session,
      :unscheduled,
      location: @school,
      organisation: @organisation,
      programme: @programme
    )
  end

  def and_i_am_a_nurse_signed_into_the_service
    sign_in @organisation.users.first
    visit "/dashboard"
    expect(page).to have_content(
      "#{@organisation.users.first.full_name} (Nurse)"
    )
  end

  def when_i_upload_the_cohort_import_containing_one_child
    cohort_data = {
      "CHILD_ADDRESS_LINE_1" => "1 Test Street",
      "CHILD_ADDRESS_LINE_2" => "2nd Floor",
      "CHILD_POSTCODE" => "TE1 1ST",
      "CHILD_TOWN" => "Testville",
      "CHILD_PREFERRED_GIVEN_NAME" => "Drop Table",
      "CHILD_DATE_OF_BIRTH" => "2011-01-01",
      "CHILD_FIRST_NAME" => "Bobby",
      "CHILD_LAST_NAME" => "Tables",
      "CHILD_NHS_NUMBER" => "999 888 6666",
      "CHILD_SCHOOL_URN" => @school.urn.to_s,
      "PARENT_1_EMAIL" => "daddy.tests@example.com",
      "PARENT_1_NAME" => "Big Daddy Tests",
      "PARENT_1_PHONE" => "07123456789",
      "PARENT_1_RELATIONSHIP" => "Father",
      "PARENT_2_EMAIL" => "",
      "PARENT_2_NAME" => "",
      "PARENT_2_PHONE" => "",
      "PARENT_2_RELATIONSHIP" => ""
    }

    @registered_parents_csv =
      CSV::Table.new([CSV::Row.new(cohort_data.keys, cohort_data.values)])

    csv_file = Tempfile.new("cohort_import.csv", Rails.root.join("tmp"))
    csv_file.write(@registered_parents_csv.to_csv)
    csv_file.close

    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
    click_on "Import child records"
    attach_file "cohort_import[csv]", csv_file.path
    click_on "Continue"
    visit cohort_import_path(CohortImport.last)
  end

  def then_i_see_that_the_cohort_has_been_uploaded
    expect(page).to have_content("1 child")
  end

  def when_i_start_creating_a_new_session_by_choosing_school_and_time
    click_on "Sessions"
    click_on "Unscheduled"
    click_on "Pilot School"
    click_on "Schedule sessions"

    click_on "Add session dates"
    expect(page).to have_content("When will sessions be held?")

    fill_in "Day", with: "1"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"
    click_on "Continue"
  end

  def and_confirm_the_session_details
    expect(page).to have_content("Edit session")

    expect(page).to have_content("ProgrammesHPV")
    expect(page).to have_content("Session datesFriday 1 March 2024")
    expect(page).to have_content(
      "Consent requestsSend on Friday 9 February 2024"
    )
    expect(page).to have_content(
      "Consent remindersSend 1 week before each session"
    )
    expect(page).to have_content("Next: Friday 23 February 2024")

    click_on "Continue"
  end

  def then_i_see_the_session_page
    expect(page).to have_content("Pilot School")
  end

  def when_i_look_at_children_that_need_consent_responses
    click_link "Check consent responses"
  end

  def then_i_see_the_children_from_the_cohort
    click_link "No response"
    expect(page).to have_content("TABLES, Bobby")
  end

  def when_i_click_on_the_child_we_registered
    click_link "TABLES, Bobby"
  end

  def then_i_see_the_childs_details_including_the_updated_nhs_number
    expect(page).to have_content(/NHS number.*999.*888.*6666/)
  end

  def given_the_day_of_the_session_comes
    travel_to(Time.zone.local(2024, 3, 1))
    sign_in @organisation.users.first
  end

  def when_i_register_verbal_consent_and_triage
    click_button "Get consent"

    choose "Big Daddy Tests"
    click_button "Continue"

    # Details for parent or guardian: leave prepopulated details
    click_button "Continue"

    choose "By phone"
    click_button "Continue"

    choose "Yes, they agree"
    click_button "Continue"

    find_all(".nhsuk-fieldset")[0].choose "No"
    find_all(".nhsuk-fieldset")[1].choose "No"
    find_all(".nhsuk-fieldset")[2].choose "No"
    find_all(".nhsuk-fieldset")[3].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    click_button "Confirm"

    click_link "TABLES, Bobby"
  end

  def then_i_should_see_that_the_patient_is_ready_for_vaccination
    expect(page).to have_content "Safe to vaccinate"
  end

  def when_i_click_on_the_register_attendance_section
    click_link "Back to consents page"
    click_link "Pilot School"
    click_link "Register attendance"
  end

  def and_i_record_the_patient_in_attendance
    click_on "Attending"
  end

  def when_i_click_on_the_vaccination_section
    click_link "Back"
    click_link "Record vaccinations"
    click_link "Vaccinate ( 1 )"
  end

  def and_i_record_the_successful_vaccination
    click_link "TABLES, Bobby"

    expect(page).to have_content("Update attendance")

    # pre-screening
    find_all(".nhsuk-fieldset")[0].choose "Yes"
    find_all(".nhsuk-fieldset")[1].choose "Yes"
    find_all(".nhsuk-fieldset")[2].choose "Yes"
    find_all(".nhsuk-fieldset")[3].choose "Yes"

    # vaccination
    find_all(".nhsuk-fieldset")[4].choose "Yes"
    choose "Left arm (upper position)"
    click_button "Continue"

    choose @batch.name
    click_button "Continue"

    click_button "Confirm"
  end

  def then_i_see_that_the_child_is_vaccinated
    click_link "Vaccinated ( 1 )"
    expect(page).to have_content "1 child vaccinated"
  end

  def and_i_cant_edit_attendance
    expect(page).not_to have_content("Update attendance")
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
