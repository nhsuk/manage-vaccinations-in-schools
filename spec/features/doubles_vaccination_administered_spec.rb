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
    and_i_check_the_patient_is_not_pregnant
    and_i_record_the_vaccination(@td_ipv_batch)
    then_i_see_the_patient_is_vaccinated_for_td_ipv

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  def given_a_doubles_session_exists
    programmes = [create(:programme, :menacwy), create(:programme, :td_ipv)]

    organisation = create(:organisation, programmes:)
    location = create(:school)

    @menacwy_batch =
      create(:batch, organisation:, vaccine: programmes.first.vaccines.first)
    @td_ipv_batch =
      create(:batch, organisation:, vaccine: programmes.second.vaccines.first)

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
    check "know what these vaccinations are for, and are happy to have them"
    check "have not already had these vaccinations"
    check "are feeling well"
    check "have no allergies which would prevent vaccination"
    check "are not taking any medication which prevents vaccination"
  end

  def and_i_record_the_vaccination(batch)
    choose "Yes"
    choose "Left arm (upper position)"
    click_on "Continue"

    choose batch.name
    click_on "Continue"

    expect(page).to have_content("Check and confirm")
    click_on "Confirm"
  end

  def then_i_see_the_patient_is_vaccinated_for_menacwy
    expect(page).to have_content("Vaccination recorded")

    # actions required
    expect(page).to have_content("Report for MenACWY")
    expect(page).to have_content("Record vaccination for Td/IPV")

    click_link @patient.full_name, match: :first
    expect(page).to have_content("Vaccinated")
  end

  def when_i_switch_to_td_ipv
    click_on "Td/IPV"
  end

  def then_i_see_the_td_ipv_vaccination_form
    expect(page).to have_content("ready for their Td/IPV vaccination?")
  end

  def and_i_check_the_patient_is_not_pregnant
    # The other pre-screening questions should be pre-checked
    # from the MenACWY vaccination.
    check "are not pregnant"
  end

  def then_i_see_the_patient_is_vaccinated_for_td_ipv
    expect(page).to have_content("Vaccination recorded")

    # patient should no longer be in record tab
    expect(page).to have_content("No children matching search criteria found")

    click_link @patient.full_name
    expect(page).to have_content("Vaccinated")
  end

  def when_vaccination_confirmations_are_sent
    VaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_confirmation_administered
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_confirmation_administered
    )
  end
end
