# frozen_string_literal: true

describe "Flu vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 10, 1)) { example.run } }

  scenario "Administered by HCA" do
    given_a_session_exists
    and_patients_exist

    when_i_visit_the_session_record_tab
    then_i_only_see_nasal_spray_patients

    when_i_click_on_the_nasal_only_patient
    then_i_am_able_to_vaccinate_them

    when_i_click_on_the_nasal_and_injection_patient
    then_i_am_able_to_vaccinate_them

    when_i_click_on_the_injection_patient
    then_i_am_not_able_to_vaccinate_them
  end

  def given_a_session_exists
    programmes = [create(:programme, :flu)]

    @team = create(:team, programmes:)
    @user = create(:healthcare_assistant, team: @team)

    @session =
      create(
        :session,
        :today,
        :requires_no_registration,
        team: @team,
        programmes:
      )
  end

  def and_patients_exist
    @patient_nasal_only =
      create(
        :patient,
        :consent_given_nasal_only_triage_not_needed,
        session: @session
      )
    @patient_nasal_and_injection =
      create(
        :patient,
        :consent_given_nasal_or_injection_triage_not_needed,
        session: @session
      )
    @patient_injection_only =
      create(
        :patient,
        :consent_given_injection_only_triage_not_needed,
        session: @session
      )
  end

  def when_i_visit_the_session_record_tab
    sign_in @user, role: :healthcare_assistant
    visit session_record_path(@session)
  end

  def then_i_only_see_nasal_spray_patients
    expect(page).to have_content(@patient_nasal_only.full_name)
    expect(page).to have_content(@patient_nasal_and_injection.full_name)
    expect(page).not_to have_content(@patient_injection_only.full_name)
  end

  def when_i_click_on_the_nasal_only_patient
    click_on @patient_nasal_only.full_name
  end

  def when_i_click_on_the_nasal_and_injection_patient
    click_on @patient_nasal_and_injection.full_name
  end

  def when_i_click_on_the_injection_patient
    # This patient won't be in the "Record" tab.
    within(".app-secondary-navigation") { click_on "Children" }
    click_on @patient_injection_only.full_name
  end

  def then_i_am_able_to_vaccinate_them
    click_on "Record vaccinations"
  end

  def then_i_am_not_able_to_vaccinate_them
    expect(page).not_to have_content("Pre-screening checks")
    expect(page).not_to have_content("ready for their")
  end
end
