# frozen_string_literal: true

# Tests:
# - [ ] Invalidated patient does exist in the database.
# - [ ] Invalidated patient does not exist in the database.

describe "Import child records" do
  scenario "PDS lookup extravaganza" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists
    and_pds_lookup_during_import_is_enabled

    when_i_visit_the_import_page
    and_i_upload_the_pds_extravaganza_import_file
    and_i_wait_for_the_import_to_complete
    then_i_should_see_the_import_page
    and_i_should_see_the_existing_patient_as_imported

    when_i_click_on_the_invalidated_patient
    then_i_should_see_invalidated_patient_record

    and_i_go_back_to_the_import_page

    when_i_click_on_the_invalid_nhs_number_patient
    then_i_should_see_invalid_nhs_number_patient_record
  end

  def given_i_am_signed_in
    @programme = create(:programme, :hpv)
    @team =
      create(
        :team,
        :with_generic_clinic,
        :with_one_nurse,
        programmes: [@programme]
      )
    sign_in @team.users.first
  end

  def and_an_hpv_programme_is_underway
    @school = create(:school, urn: "123456", team: @team)

    @session =
      create(:session, team: @team, location: @school, programmes: [@programme])
  end

  def and_an_existing_patient_record_exists
    @existing_patient =
      create(
        :patient,
        given_name: "Albert",
        family_name: "Tweedle",
        nhs_number: "9999075320",
        date_of_birth: Date.new(2009, 12, 29),
        gender_code: :male,
        address_line_1: "38A Battersea Rise",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW11 1EH",
        school: nil, # Unknown school, should be silently updated
        session: @session
      )
    @invalidated_patient =
      create(
        :patient,
        given_name: "Betty",
        family_name: "Samson",
        nhs_number: "9993524689",
        date_of_birth: Date.new(2010, 1, 1),
        gender_code: :female,
        address_line_1: "10 Downing Street",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW11 1AA",
        school: nil, # Unknown school, should be silently updated
        session: @session
      )
    @invalid_nhs_number_patient =
      create(
        :patient,
        given_name: "James",
        family_name: "Smith",
        nhs_number: nil, # Second row of valid.csv
        date_of_birth: Date.new(2010, 1, 2),
        gender_code: :male,
        address_line_1: "10 Downing Street",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW11 1AA",
        school: @school,
        session: @session
      )
  end

  def and_pds_lookup_during_import_is_enabled
    Flipper.enable(:pds_lookup_during_import)

    stub_pds_get_nhs_number_to_return_a_patient(@existing_patient.nhs_number)

    stub_pds_search_to_return_no_patients(
      "family" => @invalidated_patient.family_name,
      "given" => @invalidated_patient.given_name,
      "birthdate" => "eq#{@invalidated_patient.date_of_birth}",
      "address-postalcode" => @invalidated_patient.address_postcode
    )

    stub_pds_get_nhs_number_to_return_an_invalidated_patient(
      @invalidated_patient.nhs_number
    )

    stub_pds_get_nhs_number_to_return_an_invalid_nhs_number_response(
      "9990056846"
    )

    stub_pds_search_to_return_no_patients(
      "family" => @invalid_nhs_number_patient.family_name,
      "given" => @invalid_nhs_number_patient.given_name,
      "birthdate" => "eq#{@invalid_nhs_number_patient.date_of_birth}",
      "address-postalcode" => @invalid_nhs_number_patient.address_postcode
    )
  end

  def when_i_visit_the_import_page
    visit "/"
    click_link "Import", match: :first
  end

  def and_i_upload_the_pds_extravaganza_import_file
    click_button "Import records"
    choose "Child records"
    click_button "Continue"
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/pds_extravaganza.csv"
    )
    click_on "Continue"
  end

  def and_i_wait_for_the_import_to_complete
    perform_enqueued_jobs
    perform_enqueued_jobs
    perform_enqueued_jobs
    perform_enqueued_jobs
  end

  def and_i_go_back_to_the_import_page
    click_on "Import"
    click_on Date.current.to_fs(:long)
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def and_i_should_see_the_existing_patient_as_imported
    expect(page).not_to have_content("Actions Review TWEEDLE, Albert")
  end

  def when_i_click_on_the_invalidated_patient
    click_link "SAMSON, Betty"
  end

  def when_i_click_on_the_invalid_nhs_number_patient
    click_link "SMITH, James"
  end

  def then_i_should_see_invalidated_patient_record
    expect(page).to have_content("Record flagged as invalid")
    expect(page).to have_content("SAMSON, Betty")
    expect(page).to have_content("NHS number999 352 4689")
    expect(page).to have_content("Date of birth1 January 2010 (aged 15)")
    expect(page).to have_content("SW11 1AA")
  end

  def then_i_should_see_invalid_nhs_number_patient_record
    expect(page).to have_content("SMITH, James")
    expect(page).to have_content("NHS numberNot provided")
    expect(page).to have_content("Date of birth2 January 2010 (aged 15)")
    expect(page).to have_content("SW11 1AA")
  end
end
