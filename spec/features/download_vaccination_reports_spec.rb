# frozen_string_literal: true

describe "Download vaccination reports" do
  scenario "Download in CarePlus format" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_programme
    and_i_click_on_download_vaccination_report
    then_i_see_the_dates_page

    when_i_enter_some_dates
    then_i_see_the_file_format_page

    when_i_choose_careplus
    then_i_download_a_careplus_file
  end

  scenario "Download in Mavis format" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_programme
    and_i_click_on_download_vaccination_report
    then_i_see_the_dates_page

    when_i_enter_some_dates
    then_i_see_the_file_format_page

    when_i_choose_mavis
    then_i_download_a_mavis_file
  end

  scenario "Download in SystmOne format" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_systm_one_export_is_enabled

    when_i_go_to_the_programme
    and_i_click_on_download_vaccination_report
    then_i_see_the_dates_page

    when_i_enter_some_dates
    then_i_see_the_file_format_page

    when_i_choose_systm_one
    then_i_download_a_systm_one_file
  end

  scenario "SystmOne disabled" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    # and_systm_one_export_is_enabled

    when_i_go_to_the_programme
    and_i_click_on_download_vaccination_report
    then_i_see_the_dates_page

    when_i_enter_some_dates
    then_i_see_the_file_format_page
    and_systm_one_export_is_disabled
  end

  def given_an_hpv_programme_is_underway
    @organisation = create(:organisation, :with_one_nurse)
    @programme = create(:programme, :hpv, organisations: [@organisation])

    @session =
      create(:session, organisation: @organisation, programme: @programme)

    @patient =
      create(
        :patient,
        :triage_ready_to_vaccinate,
        given_name: "John",
        family_name: "Smith",
        programme: @programme,
        organisation: @organisation
      )

    @patient_session =
      create(:patient_session, patient: @patient, session: @session)
  end

  def and_an_administered_vaccination_record_exists
    vaccine = @programme.vaccines.first

    batch = create(:batch, organisation: @organisation, vaccine:)

    create(
      :vaccination_record,
      programme: @programme,
      patient_session: @patient_session,
      batch:
    )
  end

  def and_systm_one_export_is_enabled
    Flipper.enable(:systm_one_exporter)
  end

  def when_i_go_to_the_programme
    sign_in @organisation.users.first
    visit programme_path(@programme)
  end

  def and_i_click_on_download_vaccination_report
    click_on "Download vaccination report"
  end

  def then_i_see_the_dates_page
    expect(page).to have_content("Select a vaccination date range")
  end

  def when_i_enter_some_dates
    within all(".nhsuk-fieldset")[0] do
      fill_in "Day", with: "01"
      fill_in "Month", with: "01"
      fill_in "Year", with: "2024"
    end

    within all(".nhsuk-fieldset")[1] do
      fill_in "Day", with: "31"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2024"
    end

    click_on "Continue"
  end

  def then_i_see_the_file_format_page
    expect(page).to have_content("Select file format")
  end

  def when_i_choose_careplus
    choose "CarePlus"
    click_on "Continue"
  end

  def when_i_choose_mavis
    choose "CSV"
    click_on "Continue"
  end

  def when_i_choose_systm_one
    choose "SystmOne"
    click_on "Continue"
  end

  def then_i_download_a_careplus_file
    expect(page.status_code).to eq(200)

    expect(page).to have_content(
      "NHS Number,Surname,Forename,Date of Birth,Address Line 1"
    )
  end

  def then_i_download_a_mavis_file
    expect(page.status_code).to eq(200)

    expect(page).to have_content(
      "ORGANISATION_CODE,SCHOOL_URN,SCHOOL_NAME,CARE_SETTING,CLINIC_NAME,PERSON_FORENAME,PERSON_SURNAME"
    )
  end

  def then_i_download_a_systm_one_file
    expect(page.status_code).to eq(200)

    expect(page).to have_content(
      "Practice code,NHS number,Surname,Middle name,Forename,Gender,Date of Birth,House name,House number and road,Town"
    )
  end

  def and_systm_one_export_is_disabled
    expect(page).not_to have_selector("SystmOne")
  end
end
