# frozen_string_literal: true

describe "MenACWY and Td/IPV vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Administered" do
    given_a_doubles_session_exists
    and_a_patient_is_ready_to_be_vaccinated

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    then_i_see_the_menacwy_vaccination_form
    and_i_fill_out_pre_screening_questions
    and_i_record_the_vaccination(@menacwy_batch)
    then_i_see_the_patient_is_vaccinated_for_menacwy

    when_i_switch_to_td_ipv
    then_i_see_the_td_ipv_vaccination_form
    and_i_check_the_pre_screening_questions_again
    and_i_record_the_vaccination(@td_ipv_batch)
    then_i_see_the_patient_is_vaccinated_for_td_ipv

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccinations
    and_a_text_is_sent_to_the_parent_confirming_the_vaccinations
  end

  def given_a_doubles_session_exists
    programmes = [create(:programme, :menacwy), create(:programme, :td_ipv)]

    organisation = create(:organisation, programmes:)
    location = create(:school, organisation:)

    @menacwy_batch =
      create(
        :batch,
        :not_expired,
        organisation:,
        vaccine: programmes.first.vaccines.first
      )
    @td_ipv_batch =
      create(
        :batch,
        :not_expired,
        organisation:,
        vaccine: programmes.second.vaccines.first
      )

    @session = create(:session, organisation:, programmes:, location:)

    @nurse = create(:nurse, organisation:)
  end

  def and_a_patient_is_ready_to_be_vaccinated
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    sign_in @nurse
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def then_i_see_the_menacwy_vaccination_form
    expect(page).to have_content("ready for their MenACWY vaccination?")
  end

  def and_i_fill_out_pre_screening_questions
    check "I have checked that the above statements are true"
  end

  def and_i_record_the_vaccination(batch)
    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end

    choose batch.name
    click_on "Continue"

    expect(page).to have_content("Check and confirm")
    click_on "Confirm"
  end

  def then_i_see_the_patient_is_vaccinated_for_menacwy
    expect(page).to have_content("Vaccination outcome recorded for MenACWY")
    expect(page).to have_content(
      "You still need to record an outcome for Td/IPV."
    )

    click_on "Record vaccinations"
    expect(page).not_to have_content("for MenACWY")
    expect(page).to have_content("Record vaccination for Td/IPV")

    click_link @patient.full_name
    expect(page).to have_content("Vaccinated")
  end

  def when_i_switch_to_td_ipv
    click_on "Td/IPV"
  end

  def then_i_see_the_td_ipv_vaccination_form
    expect(page).to have_content("ready for their Td/IPV vaccination?")
  end

  def and_i_check_the_pre_screening_questions_again
    check "I have checked that the above statements are true"
  end

  def then_i_see_the_patient_is_vaccinated_for_td_ipv
    expect(page).to have_content("Vaccination outcome recorded for Td/IPV")
    expect(page).not_to have_content("You still need to record an outcome")

    click_on "Record vaccinations"
    expect(page).to have_content("No children matching search criteria found")

    click_on "Session outcomes"
    click_on @patient.full_name
    expect(page).to have_content("Vaccinated")
  end

  def when_vaccination_confirmations_are_sent
    SendVaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_vaccinations
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_administered_menacwy,
      :any
    )

    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_administered_td_ipv,
      :any
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccinations
    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_administered,
      :any
    )

    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_administered,
      :any
    )
  end
end
