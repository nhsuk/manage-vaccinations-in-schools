# frozen_string_literal: true

describe "Flu vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 10, 1)) { example.run } }

  scenario "Administered by HCA under national protocol" do
    given_a_session_exists
    and_patients_exist

    when_i_visit_the_session_record_tab
    then_i_see_all_the_patients

    when_i_click_on_the_nasal_only_patient
    then_i_am_able_to_vaccinate_them(nasal: true)

    when_i_click_on_the_nasal_and_injection_patient
    then_i_am_able_to_vaccinate_them(nasal: true)

    when_i_click_on_the_injection_patient
    then_i_am_able_to_vaccinate_them(nasal: false)
  end

  def given_a_session_exists
    @programme = create(:programme, :flu)
    programmes = [@programme]

    @team = create(:team, programmes:)

    @nasal_batch =
      create(
        :batch,
        :not_expired,
        team: @team,
        vaccine: @programme.vaccines.nasal.first
      )

    @injection_batch =
      create(
        :batch,
        :not_expired,
        team: @team,
        vaccine: @programme.vaccines.injection.first
      )

    @nurse = create(:nurse, team: @team)
    @user = create(:healthcare_assistant, team: @team)

    @session =
      create(
        :session,
        :today,
        :requires_no_registration,
        :national_protocol_enabled,
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

  def then_i_see_all_the_patients
    expect(page).to have_content(@patient_nasal_only.full_name)
    expect(page).to have_content(@patient_nasal_and_injection.full_name)
    expect(page).to have_content(@patient_injection_only.full_name)
  end

  def when_i_click_on_the_nasal_only_patient
    click_on @patient_nasal_only.full_name
  end

  def when_i_click_on_the_nasal_and_injection_patient
    click_on @patient_nasal_and_injection.full_name
  end

  def when_i_click_on_the_injection_patient
    click_on @patient_injection_only.full_name
  end

  def then_i_am_able_to_vaccinate_them(nasal:)
    check "I have checked that the above statements are true"
    select @nurse.full_name
    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)" unless nasal
    end
    click_on "Continue"

    batch = nasal ? @nasal_batch : @injection_batch

    choose batch.name
    click_on "Continue"

    click_on "Change supplier"
    choose @nurse.full_name
    (nasal ? 4 : 3).times { click_on "Continue" }

    protocol = nasal ? "Patient Group Direction (PGD)" : "National"

    expect(page).to have_content("Protocol#{protocol}")

    click_on "Confirm"
    click_on "Record vaccinations"
  end
end
