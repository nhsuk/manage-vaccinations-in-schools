# frozen_string_literal: true

describe "HPV Vaccination" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  around do |example|
    travel_to(Time.zone.local(2024, 2, 1, 12, 0, 0)) { example.run }
  end

  scenario "Download spreadsheet" do
    given_an_hpv_programme_is_underway
    and_i_am_signed_in

    when_i_go_to_a_session
    and_i_click_record_offline
    then_i_see_an_excel_file

    when_i_modify_the_excel_file_file_to_add_a_vaccination_and_export_it_to_csv
    and_i_upload_the_modified_csv_file
    then_i_see_the_vaccination_in_the_session
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])
    location = create(:location, :school)

    vaccine = programme.vaccines.active.first
    @batch = create(:batch, organisation: @organisation, vaccine:)

    @session =
      create(
        :session,
        :today,
        organisation: @organisation,
        programme:,
        location:
      )
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        session: @session,
        year_group: 8
      )
  end

  def and_i_am_signed_in
    sign_in @organisation.users.first
  end

  def when_i_go_to_a_session
    visit session_path(@session)
  end

  def and_i_click_record_offline
    click_link "Record offline (Excel)"
  end

  def then_i_see_an_excel_file
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

  def when_i_modify_the_excel_file_file_to_add_a_vaccination_and_export_it_to_csv
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

    row = csv_table.first
    row["DATE_OF_VACCINATION"] = Date.current.strftime("%d/%m/%Y")
    row["TIME_OF_VACCINATION"] = "10:00:00"
    row["VACCINATED"] = "Y"
    row["VACCINE_GIVEN"] = "Gardasil9"
    row["BATCH_NUMBER"] = @batch.name
    row["BATCH_EXPIRY_DATE"] = @batch.expiry.strftime("%d/%m/%Y")
    row["ANATOMICAL_SITE"] = "Left Upper Arm"
    row["PERFORMING_PROFESSIONAL_EMAIL"] = @organisation.users.first.email

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
  end

  def then_i_see_the_vaccination_in_the_session
    visit session_path(@session)

    click_on "Record vaccinations"
    click_on "Vaccinated"

    click_on @patient.full_name

    expect(page).to have_content("Vaccinated")
    expect(page).to have_content("HPV (Gardasil 9, #{@batch.name})")
    expect(page).to have_content("DateToday (1 February 2024)")
    expect(page).to have_content("Time10:00am")
    expect(page).to have_content(
      "VaccinatorYou (#{@organisation.users.first.full_name})"
    )
    expect(page).to have_content("SiteLeft arm (upper position)")
  end
end
