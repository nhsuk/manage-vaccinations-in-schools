# frozen_string_literal: true

describe "MMR vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 10, 1)) { example.run } }

  scenario "administered without gelatine only" do
    given_i_am_signed_in_with_mmr_programme
    and_there_is_a_session_today_with_patients_safe_to_vaccinate
    and_there_are_batches

    when_i_go_to_the_without_gelatine_only_patient
    then_i_see_the_vaccination_form

    when_i_record_that_the_patient_has_been_vaccinated
    then_i_see_only_the_vaccine_without_gelatine
    and_i_choose_a_batch(without_gelatine: true)
    then_i_see_the_check_and_confirm_page(without_gelatine: true)
    and_i_get_confirmation_after_recording

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination

    when_i_visit_the_patient_mmr_tab
    then_i_should_see_a_triage_for_the_next_vaccination_dose

    when_i_click_on_update_triage_outcome
    and_i_change_the_delay_vaccination_until_date_to_tomorrow
    and_i_save_triage
    then_i_see_an_error_that_vaccination_cannot_take_place_before_minimum_mmr_date

    when_i_enter_valid_date
    and_i_save_triage
    then_i_should_see_a_triage_with_the_new_date_for_vaccination
  end

  scenario "administered without gelatine" do
    given_i_am_signed_in_with_mmr_programme
    and_there_is_a_session_today_with_patients_safe_to_vaccinate
    and_there_are_batches

    when_i_go_to_the_without_gelatine_patient
    then_i_see_the_vaccination_form

    when_i_record_that_the_patient_has_been_vaccinated
    then_i_see_both_vaccines
    and_i_choose_a_batch(without_gelatine: true)
    then_i_see_the_check_and_confirm_page(without_gelatine: true)
    and_i_get_confirmation_after_recording

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  scenario "administered with gelatine" do
    given_i_am_signed_in_with_mmr_programme
    and_there_is_a_session_today_with_patients_safe_to_vaccinate
    and_there_are_batches

    when_i_go_to_the_with_gelatine_patient
    then_i_see_the_vaccination_form

    when_i_record_that_the_patient_has_been_vaccinated
    then_i_see_both_vaccines
    and_i_choose_a_batch(without_gelatine: false)
    then_i_see_the_check_and_confirm_page(without_gelatine: false)
    and_i_get_confirmation_after_recording

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination

    when_i_go_to_the_vaccination_record_for_the_patient
    and_i_click_on_edit_vaccination_record
    and_i_click_on_change_date
    and_i_enter_date_in_the_past
    and_i_click_on_continue
    and_i_click_on_save_changes
    then_the_delayed_triage_is_updated_to_the_new_date
  end

  def given_i_am_signed_in_with_mmr_programme
    @programme = create(:programme, :mmr)
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    @location = create(:school, team: @team)
    @session =
      create(
        :session,
        team: @team,
        programmes: [@programme],
        location: @location
      )
    sign_in @team.users.first
  end

  def and_there_is_a_session_today_with_patients_safe_to_vaccinate
    @without_gelatine_only_patient =
      create(
        :patient,
        :consent_given_without_gelatine_triage_not_needed,
        :in_attendance,
        session: @session
      )
    @without_gelatine_patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )
    @with_gelatine_patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )
  end

  def and_there_are_batches
    @with_gelatine_vaccine =
      @programme.vaccines.find_by(contains_gelatine: true)
    @without_gelatine_vaccine =
      @programme.vaccines.find_by(contains_gelatine: false)

    @with_gelatine_batch =
      create(:batch, :not_expired, team: @team, vaccine: @with_gelatine_vaccine)
    @without_gelatine_batch =
      create(
        :batch,
        :not_expired,
        team: @team,
        vaccine: @without_gelatine_vaccine
      )
  end

  def when_i_go_to_the_without_gelatine_only_patient
    visit session_consent_path(@session)
    check "Consent given for gelatine-free injection"
    click_on "Search"

    expect(page).to have_content(@without_gelatine_only_patient.full_name)
    expect(page).not_to have_content(@without_gelatine_patient.full_name)
    expect(page).not_to have_content(@with_gelatine_patient.full_name)

    @patient = @without_gelatine_only_patient

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
    expect(page).to have_content("Record MMR vaccination")
    expect(page).to have_content(
      "Is #{@patient.given_name} ready for their MMR vaccination?"
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
  end

  def then_i_see_only_the_vaccine_without_gelatine
    expect(page).to have_content(@without_gelatine_batch.name)
    expect(page).not_to have_content(@with_gelatine_batch.name)
  end

  def then_i_see_both_vaccines
    expect(page).to have_content(@without_gelatine_batch.name)
    expect(page).to have_content(@with_gelatine_batch.name)
  end

  def and_i_choose_a_batch(without_gelatine:)
    batch = (without_gelatine ? @without_gelatine_batch : @with_gelatine_batch)

    choose batch.name
    click_button "Continue"
  end

  def then_i_see_the_check_and_confirm_page(without_gelatine:)
    batch = (without_gelatine ? @without_gelatine_batch : @with_gelatine_batch)

    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@patient.full_name)
    expect(page).to have_content(batch.name)
    expect(page).to have_content(@location.name)
    expect(page).to have_content("Vaccinated")
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

  def when_i_visit_the_patient_mmr_tab
    visit session_patient_programme_path(@session, @patient, @programme)
  end

  def when_i_go_to_the_vaccination_record_for_the_patient
    visit "/dashboard"

    click_on "Children", match: :first
    click_on @patient.full_name
    click_on Date.current.to_fs(:long)
  end

  def and_i_click_on_edit_vaccination_record
    click_on "Edit vaccination record"
  end

  def then_i_should_see_a_triage_for_the_next_vaccination_dose
    expect(page).to have_content("MMR: Delay vaccination")
    expect(page).to have_content("Next dose 29 October 2024")
  end

  def then_i_should_see_a_triage_with_the_new_date_for_vaccination
    expect(page).to have_content("Next dose 05 November 2024")
  end

  def and_i_save_triage
    click_button "Save triage"
  end

  def when_i_click_on_update_triage_outcome
    click_on "Update triage outcome"
  end

  def and_i_change_the_delay_vaccination_until_date_to_tomorrow
    fill_in_date(Time.zone.local(2024, 10, 2))
  end

  def when_i_enter_valid_date
    fill_in_date(5.weeks.from_now)
  end

  def and_i_enter_date_in_the_past
    fill_in_date(2.days.ago)
  end

  def then_i_see_an_error_that_vaccination_cannot_take_place_before_minimum_mmr_date
    expect(page).to have_content(
      "The vaccination cannot take place before 29 October 2024"
    )
  end

  def fill_in_date(date)
    fill_in "Day", with: date.day
    fill_in "Month", with: date.month
    fill_in "Year", with: date.year
  end

  def and_i_click_on_change_date
    click_on "Change date"
  end

  def and_i_click_on_continue
    click_on "Continue"
  end

  def and_i_click_on_save_changes
    click_on "Save changes"
  end

  def then_the_delayed_triage_is_updated_to_the_new_date
    expect(page).to have_content("Next dose 27 October 2024")
  end
end
