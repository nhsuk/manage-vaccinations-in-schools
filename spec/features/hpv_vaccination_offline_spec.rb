# frozen_string_literal: true

describe "HPV Vaccination" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  around do |example|
    travel_to(Time.zone.local(2024, 2, 1, 12, 0, 0)) { example.run }
  end

  scenario "Download spreadsheet, record offline at a school session, upload vaccination outcomes back into Mavis" do
    given_an_hpv_programme_is_underway
    when_i_choose_to_record_offline_from_a_school_session_page
    then_i_see_an_excel_spreadsheet_for_recording_offline

    when_i_record_vaccination_outcomes_to_the_spreadsheet_and_export_it_to_csv
    and_i_upload_the_modified_csv_file
    and_i_navigate_to_the_session_page
    then_i_see_the_uploaded_vaccination_outcomes_reflected_in_the_session
  end

  scenario "Download spreadsheet, record offline at a clinic, upload vaccination outcomes back into Mavis" do
    given_an_hpv_programme_is_underway(clinic: true)
    when_i_choose_to_record_offline_from_a_clinic_page
    then_i_see_an_excel_spreadsheet_for_recording_offline

    when_i_record_vaccination_outcomes_to_the_spreadsheet_and_export_it_to_csv
    and_i_upload_the_modified_csv_file
    and_i_navigate_to_the_clinic_page
    then_i_see_the_uploaded_vaccination_outcomes_reflected_in_the_session
    and_the_clinic_location_is_displayed
  end

  def given_an_hpv_programme_is_underway(clinic: false)
    programme = create(:programme, :hpv)
    @organisation =
      create(
        :organisation,
        :with_one_nurse,
        :with_generic_clinic,
        programmes: [programme]
      )
    school = create(:location, :school)
    previous_date = 1.month.ago

    if clinic
      [previous_date, Date.current].each do |date|
        @organisation.generic_clinic_session.session_dates.create!(value: date)
      end

      @physical_clinic_location =
        create(
          :location,
          :community_clinic,
          name: "Westfield Shopping Centre",
          organisation: @organisation
        )
    end

    vaccine = programme.vaccines.active.first
    @batch = create(:batch, organisation: @organisation, vaccine:)

    @session =
      create(
        :session,
        :today,
        organisation: @organisation,
        programme:,
        location: school
      )

    @session.session_dates.create!(value: previous_date)

    @vaccinated_patient, @unvaccinated_patient =
      create_list(
        :patient,
        2,
        :consent_given_triage_not_needed,
        session: clinic ? @organisation.generic_clinic_session : @session,
        school:,
        year_group: 8
      )
    @previously_vaccinated_patient =
      create(
        :patient,
        :vaccinated,
        session: clinic ? @organisation.generic_clinic_session : @session,
        school:,
        location_name: clinic ? @physical_clinic_location.name : nil,
        year_group: 8
      )
    VaccinationRecord.last.update!(
      performed_at: previous_date,
      performed_by: @organisation.users.first
    )

    @restricted_vaccinated_patient =
      create(
        :patient,
        :vaccinated,
        :restricted,
        session: clinic ? @organisation.generic_clinic_session : @session,
        school:,
        location_name: clinic ? @physical_clinic_location.name : nil,
        year_group: 8
      )
  end

  def when_i_choose_to_record_offline_from_a_school_session_page
    sign_in @organisation.users.first
    visit session_path(@session)
    click_link "Record offline (Excel)"
  end

  def when_i_choose_to_record_offline_from_a_clinic_page
    sign_in @organisation.users.first
    visit "/dashboard"
    click_link "Sessions", match: :first
    click_link "Scheduled"
    click_on "Community clinics"
    click_link "Record offline (Excel)"
  end

  def then_i_see_an_excel_spreadsheet_for_recording_offline
    expect(page.status_code).to eq(200)

    @workbook = RubyXL::Parser.parse_buffer(page.body)
    @sheet = @workbook["Vaccinations"]
    @headers = @sheet[0].cells.map(&:value)

    expect(@headers).to include("ORGANISATION_CODE")
  end

  def excel_cell_to_csv(value)
    case value
    when Date
      value.strftime("%d/%m/%Y")
    when Time
      value.strftime("%H:%M:%S")
    else
      value
    end
  end

  def when_i_record_vaccination_outcomes_to_the_spreadsheet_and_export_it_to_csv
    # the steps below roughly approximate SAIS users:
    #
    # * opening the spreadsheet in Excel
    # * recording vaccinations into it
    # * exporting it to CSV
    #
    # ideally we could drive Excel here (or similar) but the code below is better than nothing

    array = @workbook[0].to_a[1..].map(&:cells).map { _1.map(&:value) }
    csv_table =
      CSV::Table.new(
        array.map do |row|
          CSV::Row.new(@headers, row.map { |cell| excel_cell_to_csv(cell) })
        end
      )

    row_for_vaccinated_patient =
      csv_table.find do |row|
        row["PERSON_FORENAME"] == @vaccinated_patient.given_name &&
          row["PERSON_SURNAME"] == @vaccinated_patient.family_name
      end
    row_for_vaccinated_patient["DATE_OF_VACCINATION"] = Date.current.strftime(
      "%d/%m/%Y"
    )
    row_for_vaccinated_patient["TIME_OF_VACCINATION"] = "10:00:00"
    row_for_vaccinated_patient["VACCINATED"] = "Y"
    row_for_vaccinated_patient["VACCINE_GIVEN"] = "Gardasil9"
    row_for_vaccinated_patient["BATCH_NUMBER"] = @batch.name
    row_for_vaccinated_patient["BATCH_EXPIRY_DATE"] = @batch.expiry.strftime(
      "%d/%m/%Y"
    )
    row_for_vaccinated_patient["ANATOMICAL_SITE"] = "Left Upper Arm"
    row_for_vaccinated_patient["PERFORMING_PROFESSIONAL_EMAIL"] = @organisation
      .users
      .first
      .email
    row_for_vaccinated_patient[
      "CLINIC_NAME"
    ] = @physical_clinic_location.name if @physical_clinic_location

    row_for_unvaccinated_patient =
      csv_table.find do |row|
        row["PERSON_FORENAME"] == @unvaccinated_patient.given_name &&
          row["PERSON_SURNAME"] == @unvaccinated_patient.family_name
      end
    row_for_unvaccinated_patient["DATE_OF_VACCINATION"] = Date.current.strftime(
      "%d/%m/%Y"
    )
    row_for_unvaccinated_patient["TIME_OF_VACCINATION"] = "10:01"
    row_for_unvaccinated_patient["VACCINATED"] = "N"
    row_for_unvaccinated_patient["REASON_NOT_VACCINATED"] = "did not attend"
    row_for_unvaccinated_patient[
      "PERFORMING_PROFESSIONAL_EMAIL"
    ] = @organisation.users.first.email
    row_for_unvaccinated_patient[
      "CLINIC_NAME"
    ] = @physical_clinic_location.name if @physical_clinic_location

    File.write("tmp/modified.csv", csv_table.to_csv)
  end

  def and_i_upload_the_modified_csv_file
    visit "/"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
    click_on "Import vaccination records"

    attach_file("immunisation_import[csv]", "tmp/modified.csv")
    click_on "Continue"

    click_on "1 February 2024 at 12:00pm"

    expect(page).to have_content("Completed")
    expect(page).not_to have_content("Invalid")
    expect(page).to have_content("2 previously imported records were omitted")
  end

  def and_i_navigate_to_the_session_page
    visit session_path(@session)
  end

  def and_i_navigate_to_the_clinic_page
    visit "/dashboard"
    click_on "Sessions", match: :first
    click_on "Scheduled"
    click_on "Community clinics"
  end

  def then_i_see_the_uploaded_vaccination_outcomes_reflected_in_the_session
    click_on "Record vaccinations"
    click_on "Vaccinated"

    click_on @vaccinated_patient.full_name

    expect(page).to have_content("Vaccinated")
    expect(page).to have_content("HPV (Gardasil 9, #{@batch.name})")
    expect(page).to have_content("DateToday (1 February 2024)")
    expect(page).to have_content("Time10:00am")
    expect(page).to have_content(
      "VaccinatorYou (#{@organisation.users.first.full_name})"
    )
    expect(page).to have_content("SiteLeft arm (upper position)")

    click_on "Back"
    click_on "Could not vaccinate"

    click_on @unvaccinated_patient.full_name
    expect(page).to have_content(@unvaccinated_patient.full_name)
    expect(page).to have_content("Could not vaccinate")
    expect(page).to have_content("OutcomeAbsent from session")

    click_on "Back"
    click_on "Vaccinated"

    click_on @restricted_vaccinated_patient.full_name
    expect(page).to have_content(@restricted_vaccinated_patient.full_name)
    expect(page).to have_content("Vaccinated")
    expect(page).not_to have_content("Address")
  end

  def and_the_clinic_location_is_displayed
    expect(page).to have_content("Westfield Shopping Centre")
  end
end
