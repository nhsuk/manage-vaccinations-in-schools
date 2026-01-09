# frozen_string_literal: true

describe "Download vaccination reports" do
  scenario "Download in CarePlus format" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_reports_page
    and_i_fill_in_the_form_with_careplus_format
    then_i_download_a_careplus_file
  end

  scenario "Download in Mavis format" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_reports_page
    and_i_fill_in_the_form_with_mavis_format
    then_i_download_a_mavis_file
  end

  scenario "Download in SystmOne format" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_reports_page
    and_i_fill_in_the_form_with_systm_one_format
    then_i_download_a_systm_one_file
  end

  def given_an_hpv_programme_is_underway
    @programme = Programme.hpv
    @team = create(:team, :with_one_nurse, programmes: [@programme])

    @session = create(:session, team: @team, programmes: [@programme])

    @patient =
      create(
        :patient,
        :consent_given_triage_safe_to_vaccinate,
        given_name: "John",
        family_name: "Smith",
        programmes: [@programme],
        team: @team
      )

    create(:patient_location, patient: @patient, session: @session)
  end

  def and_an_administered_vaccination_record_exists
    vaccine = @programme.vaccines.first
    batch = create(:batch, team: @team, vaccine:)

    create(
      :vaccination_record,
      programme: @programme,
      patient: @patient,
      session: @session,
      batch:
    )
  end

  def when_i_go_to_the_vaccination_reports_page
    sign_in @team.users.first
    visit new_vaccination_report_path
  end

  def and_i_fill_in_the_form_with_careplus_format
    fill_in_the_form(file_format: "CSV for CarePlus (System C)")
  end

  def and_i_fill_in_the_form_with_mavis_format
    fill_in_the_form(file_format: "CSV", match: :first)
  end

  def and_i_fill_in_the_form_with_systm_one_format
    fill_in_the_form(file_format: "CSV for SystmOne (TPP)")
  end

  def fill_in_the_form(file_format:, match: :one)
    year = AcademicYear.current
    choose "#{year} to #{year + 1}"
    choose "HPV"
    choose file_format, match: match
    click_on "Download vaccination data"
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
end
