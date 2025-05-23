# frozen_string_literal: true

describe "Manage clinic sessions" do
  around { |example| travel_to(Time.zone.local(2024, 2, 18)) { example.run } }

  scenario "Adding dates to the session, sending reminders and closing consent" do
    given_my_organisation_is_running_an_hpv_vaccination_programme

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_no_sessions

    when_i_go_to_unscheduled_sessions
    then_i_see_the_community_clinic

    when_i_click_on_the_community_clinic
    then_i_see_the_clinic_session

    when_i_click_on_schedule_sessions
    then_i_see_the_dates_page

    when_i_try_submitting_without_entering_data
    then_i_see_an_error

    when_i_choose_the_dates
    then_i_see_the_confirmation_page

    when_i_click_on_change_invitations
    then_i_see_the_change_invitations_page
    and_i_change_invitations_date
    and_i_confirm

    when_i_confirm
    then_i_should_see_the_session_details

    when_i_go_to_todays_sessions_as_a_nurse
    then_i_see_no_sessions

    when_i_go_to_unscheduled_sessions
    then_i_see_no_sessions

    when_i_go_to_scheduled_sessions
    then_i_see_the_community_clinic

    when_the_patient_has_been_invited
    and_i_click_on_the_community_clinic
    and_i_click_on_send_reminders
    then_i_see_the_send_reminders_page

    when_i_click_on_send_reminders
    then_i_see_the_reminder_confirmation
    and_the_parent_receives_a_reminder

    when_i_go_to_todays_sessions_as_a_nurse
    and_i_go_to_completed_sessions
    then_i_see_no_sessions

    when_the_parent_visits_the_consent_form
    then_they_can_give_consent

    when_the_deadline_has_passed
    then_they_can_no_longer_give_consent

    when_i_go_to_todays_sessions_as_a_nurse
    and_i_go_to_completed_sessions
    then_i_see_the_community_clinic
  end

  def given_my_organisation_is_running_an_hpv_vaccination_programme
    @programme = create(:programme, :hpv)
    @organisation =
      create(
        :organisation,
        :with_one_nurse,
        :with_generic_clinic,
        programmes: [@programme]
      )

    @session = @organisation.generic_clinic_session

    @parent = create(:parent)

    @patient =
      create(:patient, year_group: 8, session: @session, parents: [@parent])
  end

  def when_i_go_to_todays_sessions_as_a_nurse
    sign_in @organisation.users.first
    visit "/dashboard"
    click_link "Sessions", match: :first
  end

  def when_i_go_to_unscheduled_sessions
    click_link "Unscheduled"
  end

  def when_i_go_to_scheduled_sessions
    click_link "Scheduled"
  end

  def when_i_go_to_completed_sessions
    click_link "Completed"
  end

  alias_method :and_i_go_to_completed_sessions, :when_i_go_to_completed_sessions

  def then_i_see_no_sessions
    expect(page).to have_content(/There are no (sessions|locations)/)
  end

  def when_i_click_on_the_community_clinic
    click_link "Community clinics"
  end

  def then_i_see_the_clinic_session
    expect(page).to have_content("Community clinics")
    expect(page).to have_content("No sessions scheduled")
    expect(page).to have_content("Schedule sessions")
  end

  def when_i_click_on_schedule_sessions
    click_on "Schedule sessions"
    click_on "Add session dates"
  end

  def then_i_see_the_dates_page
    expect(page).to have_content("When will sessions be held?")
  end

  def when_i_try_submitting_without_entering_data
    click_on "Continue"
  end

  def then_i_see_an_error
    expect(page).to have_content("There is a problem\nEnter a date")
  end

  def when_i_choose_the_dates
    fill_in "Day", with: "10"
    fill_in "Month", with: "03"
    fill_in "Year", with: "2024"
    click_on "Add another date"

    within all(".app-add-another__list-item")[1] do
      fill_in "Day", with: "11"
      fill_in "Month", with: "03"
      fill_in "Year", with: "2024"
    end
    click_on "Add another date"

    within all(".app-add-another__list-item")[2] do
      fill_in "Day", with: "12"
      fill_in "Month", with: "03"
      fill_in "Year", with: "2024"
    end

    click_on "Add another date"

    within all(".app-add-another__list-item")[3] do
      click_on "Delete"
    end

    within all(".app-add-another__list-item")[2] do
      click_on "Delete"
    end

    click_on "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Edit session")
    expect(page).to have_content("InvitationsSend on Sunday 18 February 2024")
  end

  def when_i_click_on_change_invitations
    click_on "Change invitations"
  end

  def then_i_see_the_change_invitations_page
    expect(page).to have_content("When should parents get an invitation?")
  end

  def and_i_change_invitations_date
    fill_in "Day", with: "1"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"
  end

  def when_i_confirm
    click_on "Continue"
  end

  alias_method :and_i_confirm, :when_i_confirm

  def then_i_should_see_the_session_details
    expect(page).to have_content("10 March 2024")
    expect(page).to have_content("11 March 2024")
  end

  def then_i_see_the_community_clinic
    expect(page).to have_content("Community clinics")
  end

  def when_the_patient_has_been_invited
    create(
      :session_notification,
      :clinic_initial_invitation,
      patient: @patient,
      session: @session,
      session_date: Date.current
    )
  end

  def and_i_click_on_the_community_clinic
    click_on "Community clinics"
  end

  def when_i_click_on_send_reminders
    click_on "Send booking reminders"
  end

  alias_method :and_i_click_on_send_reminders, :when_i_click_on_send_reminders

  def then_i_see_the_send_reminders_page
    expect(page).to have_content("Remind parents to book a clinic appointment")
    expect(page).to have_content(
      "This will send booking reminders to the parents of 1 child who has not yet been sent a reminder."
    )
  end

  def then_i_see_the_reminder_confirmation
    expect(page).to have_content("Booking reminders sent for 1 child")
  end

  def and_the_parent_receives_a_reminder
    perform_enqueued_jobs
    expect_email_to @parent.email, :session_clinic_subsequent_invitation
  end

  def when_the_parent_visits_the_consent_form
    visit start_parent_interface_consent_forms_path(Session.last, @programme)
  end

  def then_they_can_give_consent
    expect(page).to have_content("Give or refuse consent for vaccinations")
  end

  def when_the_deadline_has_passed
    travel_to(Time.zone.local(2024, 3, 12))
  end

  def then_they_can_no_longer_give_consent
    visit start_parent_interface_consent_forms_path(Session.last, @programme)
    expect(page).to have_content("The deadline for responding has passed")
  end
end
