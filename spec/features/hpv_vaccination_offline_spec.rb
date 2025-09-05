# frozen_string_literal: true

describe "HPV vaccination" do
  around do |example|
    travel_to(Time.zone.local(2024, 2, 1, 12)) { example.run }
  end

  scenario "Download spreadsheet, record offline at a school session, upload vaccination outcomes back into Mavis" do
    stub_pds_get_nhs_number_to_return_a_patient

    given_an_hpv_programme_is_underway
    when_i_choose_to_record_offline_from_a_school_session_page
    then_i_see_an_excel_spreadsheet_for_recording_offline

    when_i_record_vaccination_outcomes_to_the_spreadsheet_and_export_it_to_csv
    and_i_upload_the_modified_csv_file
    then_i_see_the_successful_import
    when_i_navigate_to_the_session_page
    then_i_see_the_uploaded_vaccination_outcomes_reflected_in_the_session

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  scenario "Download spreadsheet, record offline at a clinic, upload vaccination outcomes back into Mavis" do
    stub_pds_get_nhs_number_to_return_a_patient

    given_an_hpv_programme_is_underway(clinic: true)
    when_i_choose_to_record_offline_from_a_clinic_page
    then_i_see_an_excel_spreadsheet_for_recording_offline

    when_i_record_vaccination_outcomes_to_the_spreadsheet_and_export_it_to_csv
    and_i_upload_the_modified_csv_file
    then_i_see_the_successful_import
    when_i_navigate_to_the_clinic_page
    then_i_see_the_uploaded_vaccination_outcomes_reflected_in_the_session
    and_the_clinic_location_is_displayed

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  scenario "User uploads duplicates in an offline recording for a session" do
    given_an_hpv_programme_is_underway_with_a_single_patient
    and_enqueue_sync_vaccination_records_to_nhs_feature_is_enabled

    when_i_choose_to_record_offline_from_a_school_session_page
    and_alter_an_existing_vaccination_record_to_create_a_duplicate
    and_i_upload_the_modified_csv_file
    then_i_see_a_duplicate_record_needs_review

    when_i_review_the_duplicate_record
    then_i_should_see_the_changes

    when_i_choose_to_keep_the_duplicate_record
    then_i_should_see_a_success_message
    and_the_vaccination_record_is_synced_to_nhs

    when_i_change_the_vaccination_outcome_to_not_vaccinated
    and_i_upload_the_modified_csv_file
    and_i_review_the_duplicate_record
    and_i_choose_to_keep_the_duplicate_record
    then_i_should_see_a_success_message
    and_the_vaccination_record_is_deleted_from_nhs
  end

  def given_an_hpv_programme_is_underway(clinic: false)
    programmes = [create(:programme, :hpv)]

    @team = create(:team, :with_one_nurse, :with_generic_clinic, programmes:)
    school = create(:school, team: @team)
    previous_date = 1.month.ago

    if clinic
      [previous_date, Date.current].each do |date|
        @team
          .generic_clinic_session(academic_year: AcademicYear.current)
          .session_dates
          .create!(value: date)
      end

      @physical_clinic_location =
        create(
          :community_clinic,
          name: "Westfield Shopping Centre",
          team: @team
        )
    end

    vaccine = programmes.first.vaccines.active.first
    @batch = create(:batch, :not_expired, team: @team, vaccine:)

    create(:gp_practice, ods_code: "Y12345")

    @session =
      create(:session, :today, team: @team, programmes:, location: school)

    @session.session_dates.create!(value: previous_date)

    @vaccinated_patient, @unvaccinated_patient =
      create_list(
        :patient,
        2,
        :consent_given_triage_not_needed,
        session:
          (
            if clinic
              @team.generic_clinic_session(academic_year: AcademicYear.current)
            else
              @session
            end
          ),
        school:,
        year_group: 8
      )
    @previously_vaccinated_patient =
      create(
        :patient,
        :vaccinated,
        session:
          (
            if clinic
              @team.generic_clinic_session(academic_year: AcademicYear.current)
            else
              @session
            end
          ),
        school:,
        location_name: clinic ? @physical_clinic_location.name : nil,
        year_group: 8
      )
    VaccinationRecord.last.update!(
      performed_at: previous_date,
      performed_by: @team.users.first,
      notify_parents: true
    )

    @restricted_vaccinated_patient =
      create(
        :patient,
        :vaccinated,
        :restricted,
        session:
          (
            if clinic
              @team.generic_clinic_session(academic_year: AcademicYear.current)
            else
              @session
            end
          ),
        school:,
        location_name: clinic ? @physical_clinic_location.name : nil,
        year_group: 8
      )
  end

  def given_an_hpv_programme_is_underway_with_a_single_patient
    programmes = [create(:programme, :hpv)]

    @team = create(:team, :with_one_nurse, :with_generic_clinic, programmes:)
    school = create(:school, team: @team)
    previous_date = 1.month.ago

    vaccine = programmes.first.vaccines.active.first
    @batch = create(:batch, :not_expired, team: @team, vaccine:)

    @session =
      create(:session, :today, team: @team, programmes:, location: school)

    @session.session_dates.create!(value: previous_date)

    @previously_vaccinated_patient =
      create(:patient, :vaccinated, session: @session, school:, year_group: 8)
    VaccinationRecord.last.update!(
      performed_at: previous_date,
      performed_by: @team.users.first,
      notify_parents: true
    )
  end

  def and_enqueue_sync_vaccination_records_to_nhs_feature_is_enabled
    Flipper.enable(:enqueue_sync_vaccination_records_to_nhs)
    Flipper.enable(:immunisations_fhir_api_integration)

    immunisation_uuid = Random.uuid
    @stubbed_post_request = stub_immunisations_api_post(uuid: immunisation_uuid)
    @stubbed_put_request = stub_immunisations_api_put(uuid: immunisation_uuid)
    @stubbed_delete_request =
      stub_immunisations_api_delete(uuid: immunisation_uuid)
  end

  def when_i_choose_to_record_offline_from_a_school_session_page
    sign_in @team.users.first
    visit session_path(@session)
    click_link "Record offline"
  end

  def when_i_choose_to_record_offline_from_a_clinic_page
    sign_in @team.users.first
    visit "/dashboard"
    click_link "Sessions", match: :first
    choose "Scheduled"
    click_button "Update results"
    click_link "Community clinic"
    click_link "Record offline"
  end

  def and_alter_an_existing_vaccination_record_to_create_a_duplicate
    expect(page.status_code).to eq(200)

    @workbook = RubyXL::Parser.parse_buffer(page.body)
    @sheet = @workbook["Vaccinations"]
    @headers = @sheet[0].cells.map(&:value)

    array = @workbook[0].to_a[1..].map(&:cells).map { it.map(&:value) }
    csv_table =
      CSV::Table.new(
        array.map do |row|
          CSV::Row.new(@headers, row.map { |cell| excel_cell_to_csv(cell) })
        end
      )

    row_for_vaccinated_patient = csv_table[0]

    # Change details for the patient
    row_for_vaccinated_patient["NHS_NUMBER"] = ""
    row_for_vaccinated_patient["PERSON_FORENAME"] = "New name"

    # Change details for the vaccination record
    row_for_vaccinated_patient["DOSE_SEQUENCE"] = "2"
    row_for_vaccinated_patient["ANATOMICAL_SITE"] = "Right Upper Arm"

    File.write("tmp/modified.csv", csv_table.to_csv)
  end

  def when_i_change_the_vaccination_outcome_to_not_vaccinated
    csv_table = CSV.read("tmp/modified.csv", headers: true)

    row_for_vaccinated_patient = csv_table[0]
    row_for_vaccinated_patient["VACCINATED"] = "N"
    row_for_vaccinated_patient["REASON_NOT_VACCINATED"] = "refused"
    row_for_vaccinated_patient["BATCH_EXPIRY_DATE"] = nil
    row_for_vaccinated_patient["BATCH_NUMBER"] = nil
    row_for_vaccinated_patient["ANATOMICAL_SITE"] = nil

    File.write("tmp/modified.csv", csv_table.to_csv)
  end

  def when_i_review_the_duplicate_record
    click_on "Review"
  end
  alias_method :and_i_review_the_duplicate_record,
               :when_i_review_the_duplicate_record

  def then_i_should_see_the_changes
    expect(page).to have_css(
      ".app-highlight",
      text: "Right arm (upper position)"
    )
  end

  def when_i_choose_to_keep_the_duplicate_record
    choose "Use uploaded vaccination record"
    click_on "Resolve duplicate"
  end
  alias_method :and_i_choose_to_keep_the_duplicate_record,
               :when_i_choose_to_keep_the_duplicate_record

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

    array = @workbook[0].to_a[1..].map(&:cells).map { it.map(&:value) }
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
    row_for_vaccinated_patient["PERFORMING_PROFESSIONAL_EMAIL"] = @team
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
    row_for_unvaccinated_patient["VACCINE_GIVEN"] = "Gardasil9"
    row_for_unvaccinated_patient["REASON_NOT_VACCINATED"] = "did not attend"
    row_for_unvaccinated_patient["NOTES"] = "Some notes."
    row_for_unvaccinated_patient["PERFORMING_PROFESSIONAL_EMAIL"] = @team
      .users
      .first
      .email
    row_for_unvaccinated_patient[
      "CLINIC_NAME"
    ] = @physical_clinic_location.name if @physical_clinic_location

    File.write("tmp/modified.csv", csv_table.to_csv)
  end

  def and_i_upload_the_modified_csv_file
    travel 1.minute

    visit "/"

    click_on "Import", match: :first
    click_on "Import records"
    choose "Vaccination records"
    click_on "Continue"

    attach_file("immunisation_import[csv]", "tmp/modified.csv")
    click_on "Continue"

    wait_for_import_to_complete(ImmunisationImport)
  end

  def when_i_navigate_to_the_session_page
    visit "/dashboard"
    click_on "Sessions", match: :first
    choose "Scheduled"
    click_on "Update results"
    click_on @session.location.name
  end

  def when_i_navigate_to_the_clinic_page
    visit "/dashboard"
    click_on "Sessions", match: :first
    choose "Scheduled"
    click_on "Update results"
    click_on "Community clinic"
  end

  def then_i_see_the_uploaded_vaccination_outcomes_reflected_in_the_session
    within(".app-secondary-navigation") { click_on "Children" }
    choose "Vaccinated", match: :first
    click_on "Update results"

    click_on @vaccinated_patient.full_name

    expect(page).to have_content("Vaccinated")

    patient_url = current_url

    click_on "1 February 2024"
    expect(page).to have_content("Gardasil 9")
    expect(page).to have_content(@batch.name)
    expect(page).to have_content("DateToday (1 February 2024)")
    expect(page).to have_content("Time10:00am")
    expect(page).to have_content(
      "VaccinatorYou (#{@team.users.first.full_name})"
    )
    expect(page).to have_content("SiteLeft arm (upper position)")

    visit patient_url
    within(".nhsuk-breadcrumb__list") { click_on "Children" }
    choose "No outcome"
    click_on "Update results"

    click_on @unvaccinated_patient.full_name
    expect(page).to have_content(@unvaccinated_patient.full_name)
    expect(page).to have_content("No outcome")
    expect(page).to have_content("Absent from session")

    visit patient_url
    within(".nhsuk-breadcrumb__list") { click_on "Children" }
    choose "Vaccinated", match: :first
    click_on "Update results"

    click_on @restricted_vaccinated_patient.full_name
    expect(page).to have_content(@restricted_vaccinated_patient.full_name)
    expect(page).to have_content("Vaccinated")
  end

  def and_the_clinic_location_is_displayed
    expect(page).to have_content("Westfield Shopping Centre")
  end

  def when_vaccination_confirmations_are_sent
    SendVaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    expect_email_to(
      @vaccinated_patient.consents.last.parent.email,
      :vaccination_administered_hpv,
      :any
    )

    expect_email_to(
      @unvaccinated_patient.consents.last.parent.email,
      :vaccination_not_administered,
      :any
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    expect_sms_to(
      @vaccinated_patient.consents.last.parent.phone,
      :vaccination_administered,
      :any
    )

    expect_sms_to(
      @unvaccinated_patient.consents.last.parent.phone,
      :vaccination_not_administered,
      :any
    )
  end

  def then_i_see_the_successful_import
    expect(page).to have_content("Completed")
    expect(page).not_to have_content("Invalid")

    expect(page).to have_content("4 vaccination records")
    expect(page).to have_content(
      "2 records were not imported because they already exist in Mavis"
    )
  end

  def then_i_see_a_duplicate_record_needs_review
    expect(page).to have_content(
      "1 record has import issues to resolve before it can be imported into Mavis"
    )
  end

  def then_i_should_see_a_success_message
    expect(page).to have_content("Record updated")
  end

  def and_the_vaccination_record_is_synced_to_nhs
    # expect(SyncVaccinationRecordToNHSJob).to have_been_enqueued.exactly(2).times
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    expect(@stubbed_post_request).to have_been_requested
  end

  def and_the_vaccination_record_is_deleted_from_nhs
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    expect(@stubbed_delete_request).to have_been_requested
  end
end
