# frozen_string_literal: true

describe "Flu vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 10, 1)) { example.run } }

  scenario "Administered with nasal spray" do
    given_i_am_signed_in_with_flu_programme
    and_there_is_a_flu_session_today_with_two_patients_ready_to_vaccinate
    and_there_are_nasal_and_injection_batches
    and_sync_vaccination_records_to_nhs_on_create_feature_is_enabled

    when_i_go_to_the_nasal_only_patient
    and_i_record_that_the_patient_has_been_vaccinated_with_nasal_spray
    then_i_see_the_check_and_confirm_page_for_nasal_spray
    and_i_get_confirmation_after_recording
    and_the_vaccination_record_is_synced_to_nhs
  end

  scenario "Administered with injection" do
    given_i_am_signed_in_with_flu_programme
    and_there_is_a_flu_session_today_with_two_patients_ready_to_vaccinate
    and_there_are_nasal_and_injection_batches

    when_i_go_to_the_injection_only_patient
    and_i_record_that_the_patient_has_been_vaccinated_with_injection
    then_i_see_the_check_and_confirm_page_for_injection
    and_i_get_confirmation_after_recording
  end

  scenario "Switching between nasal and injection" do
    given_i_am_signed_in_with_flu_programme
    and_there_is_a_flu_session_today_with_two_patients_ready_to_vaccinate
    and_there_are_nasal_and_injection_batches

    when_i_go_to_the_nasal_only_patient
    and_i_record_that_the_patient_has_been_vaccinated_with_nasal_spray
    then_i_see_the_check_and_confirm_page_for_nasal_spray

    when_i_change_the_vaccine_method_to_injection
    and_i_pick_a_batch_for_injection
    then_i_see_the_check_and_confirm_page_for_injection
  end

  def given_i_am_signed_in_with_flu_programme
    @programme = create(:programme, :flu)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    @location = create(:school)
    @session =
      create(
        :session,
        organisation: @organisation,
        programmes: [@programme],
        location: @location
      )
    sign_in @organisation.users.first
  end

  def and_there_is_a_flu_session_today_with_two_patients_ready_to_vaccinate
    @nasal_patient =
      create(
        :patient,
        :consent_given_nasal_only_triage_not_needed,
        :in_attendance,
        session: @session
      )
    @injection_patient =
      create(
        :patient,
        :consent_given_injection_only_triage_not_needed,
        :in_attendance,
        session: @session
      )
  end

  def and_there_are_nasal_and_injection_batches
    @nasal_vaccine = create(:vaccine, programme: @programme, method: :nasal)
    @nasal_batch =
      create(
        :batch,
        :not_expired,
        organisation: @organisation,
        vaccine: @nasal_vaccine
      )
    @injection_vaccine =
      create(:vaccine, programme: @programme, method: :injection)
    @injection_batch =
      create(
        :batch,
        :not_expired,
        organisation: @organisation,
        vaccine: @injection_vaccine
      )
  end

  def and_sync_vaccination_records_to_nhs_on_create_feature_is_enabled
    Flipper.enable(:sync_vaccination_records_to_nhs_on_create)
  end

  def when_i_go_to_the_nasal_only_patient
    visit session_record_path(@session)
    @patient = @nasal_patient
    click_link @patient.full_name
  end

  def when_i_go_to_the_injection_only_patient
    visit session_record_path(@session)
    @patient = @injection_patient
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_has_been_vaccinated_with_nasal_spray
    within all("section")[0] do
      check "has confirmed the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      click_button "Continue"
    end

    choose @nasal_batch.name
    click_button "Continue"
  end

  def and_i_record_that_the_patient_has_been_vaccinated_with_injection
    within all("section")[0] do
      check "has confirmed the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end

    choose @injection_batch.name
    click_button "Continue"
  end

  def then_i_see_the_check_and_confirm_page_for_nasal_spray
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@patient.full_name)
    expect(page).to have_content(@nasal_batch.name)
    expect(page).to have_content("Nasal spray")
    expect(page).to have_content("Nose")
    expect(page).to have_content(@location.name)
    expect(page).to have_content("Vaccinated")
  end

  def and_i_get_confirmation_after_recording
    click_button "Confirm"
    expect(page).to have_content("Vaccination outcome recorded for Flu")
  end

  def then_i_see_the_check_and_confirm_page_for_injection
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@patient.full_name)
    expect(page).to have_content(@injection_batch.name)
    expect(page).to have_content("Intramuscular")
    expect(page).to have_content("Left arm (upper position)")
    expect(page).to have_content(@location.name)
    expect(page).to have_content("Vaccinated")
  end

  def when_i_change_the_vaccine_method_to_injection
    click_link "Change method"
    choose "Intramuscular"
    choose "Left arm (upper position)"
    click_button "Continue"
  end

  def and_i_pick_a_batch_for_injection
    expect(page).not_to have_content(@nasal_batch.name)
    expect(page).not_to have_checked_field
    choose @injection_batch.name
    click_button "Continue"
  end

  def and_the_vaccination_record_is_synced_to_nhs
    assert_enqueued_with(job: SyncVaccinationRecordToNHSJob)
  end
end
