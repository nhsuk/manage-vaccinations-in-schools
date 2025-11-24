# frozen_string_literal: true

describe "MMRV vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 10, 1)) { example.run } }

  scenario "administered at community clinic" do
    given_mmrv_vaccinations_are_enabled
    and_i_am_signed_in_as_a_nurse
    and_a_patient_is_ready_for_mmrv_vaccination_in_a_community_clinic

    when_i_go_to_the_consent_tab
    then_i_should_consent_for_mmrv
    when_i_go_to_the_patient
    then_i_see_the_vaccination_form

    when_i_record_that_the_patient_has_been_vaccinated
    then_i_see_the_check_and_confirm_page
    and_i_get_confirmation_after_recording

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    and_i_should_see_a_triage_for_the_next_vaccination_dose
  end

  def given_mmrv_vaccinations_are_enabled
    Flipper.enable(:mmrv)
  end

  def and_i_am_signed_in_as_a_nurse
    @programme = Programme.mmr
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    vaccine = @programme.vaccines.injection.first
    @batch = create(:batch, :not_expired, team: @team, vaccine:)
    sign_in @team.users.first
  end

  def and_a_patient_is_ready_for_mmrv_vaccination_in_a_community_clinic
    location = create(:generic_clinic, team: @team)
    @session =
      create(:session, team: @team, programmes: [@programme], location:)
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session,
        date_of_birth: Programme::MIN_MMRV_ELIGIBILITY_DATE + 1.month
      )
    @community_clinic = create(:community_clinic, team: @team)
  end
  def when_i_go_to_the_consent_tab
    visit session_consent_path(@session)
  end

  def then_i_should_consent_for_mmrv
    expect(page).to have_content("MMRVConsent given")
  end

  def when_i_go_to_the_patient
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def when_i_go_to_the_without_gelatine_patient
    visit session_consent_path(@session)
    check "Consent given"
    click_on "Search"

    expect(page).not_to have_content(@without_gelatine_only_patient.full_name)
    expect(page).to have_content(@without_gelatine_patient.full_name)
    expect(page).to have_content(@with_gelatine_patient.full_name)

    @patient = @without_gelatine_patient

    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def when_i_go_to_the_with_gelatine_patient
    visit session_consent_path(@session)
    check "Consent given"
    click_on "Search"

    expect(page).not_to have_content(@without_gelatine_only_patient.full_name)
    expect(page).to have_content(@without_gelatine_patient.full_name)
    expect(page).to have_content(@with_gelatine_patient.full_name)

    @patient = @with_gelatine_patient

    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def then_i_see_the_vaccination_form
    expect(page).to have_content("Record MMRV vaccination")
    expect(page).to have_content(
      "Is #{@patient.given_name} ready for their MMRV vaccination?"
    )
  end

  def when_i_record_that_the_patient_has_been_vaccinated
    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end

    choose @batch.name
    click_button "Continue"

    expect(page).to have_content("Where was the MMRV vaccination offered?")
    choose @community_clinic.name
    click_button "Continue"
  end

  def then_i_see_the_check_and_confirm_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("ProgrammeMMRV")
  end

  def and_i_get_confirmation_after_recording
    click_button "Confirm"
    expect(page).to have_content("Vaccination outcome recorded for MMR")
  end

  def when_vaccination_confirmations_are_sent
    SendVaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_administered_mmr
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_administered
    )
  end

  def and_i_click_on_edit_vaccination_record
    click_on "Edit vaccination record"
  end

  def and_i_should_see_a_triage_for_the_next_vaccination_dose
    expect(page).to have_content("MMRV: Delay vaccination")
    expect(page).to have_content("Next dose 29 October 2024")
  end

  def then_i_should_see_a_triage_with_the_new_date_for_vaccination
    expect(page).to have_content("Next dose 05 November 2024")
  end
end
