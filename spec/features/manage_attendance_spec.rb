# frozen_string_literal: true

describe "Manage attendance" do
  before do
    Flipper.enable(:release_1b)
    Flipper.enable(:record_attendance)
  end

  after do
    Flipper.disable(:release_1b)
    Flipper.disable(:record_attendance)
  end

  around { |example| travel_to(Time.zone.local(2024, 2, 29)) { example.run } }

  scenario "Recording attendance for a patient" do
    given_my_organisation_is_running_an_hpv_vaccination_programme
    and_there_is_a_vaccination_session_today_with_a_patient_ready_to_vaccinate

    when_i_go_to_the_patient
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
    @programme = create(:programme, :hpv_all_vaccines)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
  end

  def and_there_is_a_vaccination_session_today_with_a_patient_ready_to_vaccinate
    location = create(:location, :school)
    @session =
      create(
        :session,
        :today,
        programme: @programme,
        organisation: @organisation,
        location:
      )

    create(
      :patient_session,
      :consent_given_triage_not_needed,
      programme: @programme,
      session: @session
    )

    @patient = @session.reload.patients.first
  end

  def when_i_go_to_the_patient
    sign_in @organisation.users.first
    visit dashboard_path
    click_link "Sessions", match: :first
    click_link @session.location.name
    click_link "Record vaccinations"
    click_link @patient.full_name
  end

  def then_the_patient_is_not_registered_yet
    expect(page).to have_content("Not registered yet")
  end

  def and_i_am_not_able_to_vaccinate
    expect(page).not_to have_content("Did they get the HPV vaccine?")
  end

  def when_i_choose_the_patient_has_not_been_registered_yet
    click_link "Update attendance"
    choose "They have not been registered yet", match: :first
    click_button "Save changes"
  end

  def and_i_see_the_not_registered_flash
    expect(page).to have_content("#{@patient.full_name} is not registered yet")
  end

  def when_i_choose_the_patient_is_absent
    click_link "Update attendance"
    choose "No, they are absent"
    click_button "Save changes"
  end

  def then_the_patient_is_absent
    expect(page).to have_content("Absent from today")
  end

  def and_i_see_the_absent_flash
    expect(page).to have_content("#{@patient.full_name} is absent from today")
  end

  def when_i_choose_the_patient_is_attending
    click_link "Update attendance"
    choose "Yes, they are attending"
    click_button "Save changes"
  end

  def then_the_patient_is_attending
    expect(page).to have_content("Attending today")
  end

  def and_i_see_the_attending_flash
    expect(page).to have_content("#{@patient.full_name} is attending today")
  end

  def and_i_can_vaccinate
    expect(page).to have_content("Did they get the HPV vaccine?")
  end

  def when_i_go_to_the_activity_log
    click_link "Activity log"
  end

  def then_i_see_the_attendance_event
    expect(page).to have_content("Attended session")
  end
end
