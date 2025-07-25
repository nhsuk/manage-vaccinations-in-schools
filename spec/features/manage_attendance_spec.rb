# frozen_string_literal: true

describe "Manage attendance" do
  around { |example| travel_to(Time.zone.local(2024, 2, 29)) { example.run } }

  scenario "Recording attendance for a patient" do
    given_my_organisation_is_running_an_hpv_vaccination_programme
    and_there_is_a_vaccination_session_today_with_a_patient_ready_to_vaccinate

    when_i_go_to_the_session
    and_i_click_on_the_register_tab
    then_i_see_the_register_tab
    and_i_see_the_actions_required

    when_i_register_a_patient_as_attending
    then_i_see_the_attending_flash

    when_i_register_a_patient_as_absent
    then_i_see_the_absent_flash

    when_i_go_to_the_session_outcomes
    then_i_see_a_patient_is_absent

    when_i_go_to_a_patient
    then_the_patient_is_not_registered_yet
    and_i_am_not_able_to_vaccinate

    when_i_choose_the_patient_has_not_been_registered_yet
    then_the_patient_is_not_registered_yet
    and_i_see_the_not_registered_flash

    when_i_choose_the_patient_is_absent
    then_the_patient_is_absent
    and_i_see_the_absent_flash

    when_i_choose_the_patient_is_attending
    then_the_patient_is_attending
    and_i_see_the_attending_flash
    and_i_can_vaccinate

    when_i_go_to_the_activity_log
    then_i_see_the_attendance_event
  end

  def given_my_organisation_is_running_an_hpv_vaccination_programme
    @programmes = [create(:programme, :hpv_all_vaccines)]
    @organisation =
      create(:organisation, :with_one_nurse, programmes: @programmes)
  end

  def and_there_is_a_vaccination_session_today_with_a_patient_ready_to_vaccinate
    location = create(:school, organisation: @organisation)
    @session =
      create(
        :session,
        :today,
        programmes: @programmes,
        organisation: @organisation,
        location:
      )

    create_list(
      :patient_session,
      3,
      :consent_given_triage_not_needed,
      programmes: @programmes,
      session: @session
    )
  end

  def when_i_go_to_the_session
    sign_in @organisation.users.first
    visit dashboard_path
    click_link "Sessions", match: :first
    click_link @session.location.name
  end

  def and_i_click_on_the_register_tab
    click_link "Register"
  end

  def then_i_see_the_register_tab
    expect(page).to have_content("Registration status")
  end

  def and_i_see_the_actions_required
    # This should be shown once per patient (there are 3 patients).
    expect(page).to have_content("Record vaccination for HPV").exactly(3).times
  end

  def when_i_register_a_patient_as_attending
    click_button "Attending", match: :first
  end

  def when_i_register_a_patient_as_absent
    click_button "Absent", match: :first
  end

  def when_i_go_to_the_session_outcomes
    click_on "Session outcomes"
  end

  def then_i_see_a_patient_is_absent
    choose "Absent from session"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
  end

  def when_i_go_to_a_patient
    choose "Any"
    click_on "Update results"

    click_link PatientSession
                 .where
                 .missing(:session_attendances)
                 .find_by(session: @session)
                 .patient
                 .full_name
  end

  def then_the_patient_is_not_registered_yet
    expect(page).to have_content("Not registered yet")
  end

  def and_i_am_not_able_to_vaccinate
    expect(page).not_to have_content("ready for their HPV vaccination?")
  end

  def when_i_choose_the_patient_has_not_been_registered_yet
    click_link "Update attendance"
    choose "They have not been registered yet", match: :first
    click_button "Save changes"
  end

  def and_i_see_the_not_registered_flash
    expect(page).to have_content("is not registered yet")
  end

  def when_i_choose_the_patient_is_absent
    click_link "Update attendance"
    choose "No, they are absent"
    click_button "Save changes"
  end

  def then_the_patient_is_absent
    expect(page).to have_content("Absent from session")
  end

  def and_i_see_the_absent_flash
    expect(page).to have_content("is absent from today")
  end
  alias_method :then_i_see_the_absent_flash, :and_i_see_the_absent_flash

  def when_i_choose_the_patient_is_attending
    click_link "Update attendance"
    choose "Yes, they are attending"
    click_button "Save changes"
  end

  def then_the_patient_is_attending
    expect(page).to have_content("Attending session")
  end

  def and_i_see_the_attending_flash
    expect(page).to have_content("is attending today")
  end
  alias_method :then_i_see_the_attending_flash, :and_i_see_the_attending_flash

  def and_i_can_vaccinate
    expect(page).to have_content("ready for their HPV vaccination?")
  end

  def when_i_go_to_the_activity_log
    click_link "Session activity and notes"
  end

  def then_i_see_the_attendance_event
    expect(page).to have_content("Attended session")
  end
end
