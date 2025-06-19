# frozen_string_literal: true

describe "Triage" do
  scenario "Nurse triages a patient and then consent is refused" do
    stub_pds_search_to_return_no_patients

    given_a_programme_with_a_running_session

    when_i_go_to_the_patient_that_needs_triage
    and_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_patient_is_ready

    when_i_go_to_the_consent_form_as_a_parent
    and_i_refuse_consent
    then_i_see_the_confirmation_page

    when_i_wait_for_background_jobs_to_complete
    and_i_go_to_the_patient_with_conflicting_consent
    then_i_see_the_patient_is_not_safe_to_vaccinate
  end

  def given_a_programme_with_a_running_session
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programmes: [@programme]
      )

    @patient =
      create(
        :patient_session,
        :consent_given_triage_needed,
        programmes: [@programme],
        session: @session
      ).patient
  end

  def when_i_go_to_the_patient_that_needs_triage
    sign_in @organisation.users.first

    visit session_triage_path(@session)
    choose "Needs triage"
    click_on "Update results"

    click_link @patient.full_name
  end

  def and_i_record_that_they_are_safe_to_vaccinate
    choose "Yes, it’s safe to vaccinate"
    click_on "Save triage"
  end

  def then_i_see_the_patient_is_ready
    click_on @patient.full_name, match: :first
    expect(page).to have_content("Safe to vaccinate")
  end

  def when_i_go_to_the_consent_form_as_a_parent
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def and_i_refuse_consent
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @patient.given_name
    fill_in "Last name", with: @patient.family_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @patient.date_of_birth.day
    fill_in "Month", with: @patient.date_of_birth.month
    fill_in "Year", with: @patient.date_of_birth.year
    click_on "Continue"

    expect(page).to have_content("Confirm your child’s school")
    choose "Yes, they go to this school"
    click_on "Continue"

    expect(page).to have_content("About you")
    fill_in "Full name", with: "Jane #{@patient.family_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"
    check "Tick this box if you’d like to get updates by text message"
    click_on "Continue"

    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"
    click_on "Continue"

    expect(page).to have_content("Do you agree")
    choose "No"
    click_on "Continue"

    expect(page).to have_content(
      "Please tell us why you do not agree to your child having the HPV vaccination"
    )
    choose "Medical reasons"
    click_on "Continue"

    expect(page).to have_content(
      "What medical reasons prevent your child from being vaccinated?"
    )
    fill_in "Give details", with: "They have a weakened immune system"
    click_on "Continue"

    click_on "Confirm"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content(
      "You’ve told us that you do not want #{@patient.full_name(context: :parents)} " \
        "to get the HPV vaccination at school"
    )
  end

  def when_i_wait_for_background_jobs_to_complete
    perform_enqueued_jobs
  end

  def and_i_go_to_the_patient_with_conflicting_consent
    visit session_consent_path(@session)
    check "Conflicting consent"
    click_on "Update results"

    click_on @patient.full_name
  end

  def then_i_see_the_patient_is_not_safe_to_vaccinate
    expect(page).to have_content("Conflicting consent")
  end
end
