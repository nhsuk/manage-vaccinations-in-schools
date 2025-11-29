# frozen_string_literal: true

describe "Download vaccination reports (single page)" do
  scenario "Download a vaccination report" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_visit_the_single_page_form
    and_i_fill_in_the_form
    then_i_download_a_csv_file
  end

  scenario "Validation errors when required fields are missing" do
    given_an_hpv_programme_is_underway

    when_i_visit_the_single_page_form
    and_i_submit_without_filling_in_the_form
    then_i_see_validation_errors
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

  def when_i_visit_the_single_page_form
    sign_in @team.users.first
    visit new_vaccination_report_path
  end

  def and_i_fill_in_the_form
    choose "#{AcademicYear.current} to #{AcademicYear.current + 1}"
    choose "HPV"
    choose "CSV"
    click_on "Download vaccination data"
  end

  def and_i_submit_without_filling_in_the_form
    click_on "Download vaccination data"
  end

  def then_i_download_a_csv_file
    expect(page.status_code).to eq(200)
    expect(page).to have_content("ORGANISATION_CODE")
  end

  def then_i_see_validation_errors
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Choose a programme")
    expect(page).to have_content("Choose a file format")
  end
end
