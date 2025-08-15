# frozen_string_literal: true

describe "Import child records" do
  let(:today) { Time.zone.local(2025, 9, 1, 12, 0, 0) }

  around { |example| travel_to(today) { example.run } }

  scenario "PDS lookup extravaganza with multiple patient scenarios" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists
    and_pds_lookup_during_import_is_enabled

    when_i_visit_the_import_page
    and_i_upload_import_file("pds_extravaganza.csv")
    then_i_should_see_the_import_page
    and_i_should_see_one_new_patient_created

    # Case 1: Patient with existing NHS number (Albert) - nothing should happen
    and_i_see_the_patient_uploaded_with_nhs_number

    # Case 2: Existing patient without NHS number (Betty) - should not show duplicate review
    and_i_do_not_see_an_import_review_for_the_first_patient_uploaded_without_nhs_number
    when_i_click_on_the_patient_without_review
    then_i_see_the_new_patient_has_an_nhs_number

    # Case 3: Existing patient with NHS number (Catherine) - should show duplicate review
    when_i_go_back_to_the_import_page
    then_i_see_an_import_review_for_the_second_patient_uploaded_without_nhs_number
    when_i_click_review
    then_i_see_both_records_have_an_nhs_number
    when_i_use_duplicate_record_during_merge
    then_the_existing_patient_has_an_nhs_number_in_mavis

    # Case 4: New patient without NHS number (Charlie) - should be created with NHS number from PDS
    when_i_go_back_to_the_import_page
    when_i_click_on_new_patient_uploaded_without_an_nhs_number
    then_i_see_the_new_patient_now_has_an_nhs_number
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
    @existing_patient_uploaded_with_nhs_number =
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
        school: nil,
        session: @session
      )

    # Betty - will match exactly except NHS number (no review needed)
    @existing_patient_uploaded_without_nhs_number =
      create(
        :patient,
        given_name: "Betty",
        family_name: "Samson",
        nhs_number: nil,
        date_of_birth: Date.new(2010, 1, 1),
        gender_code: :female,
        address_line_1: "123 High Street",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        school: nil,
        session: @session
      )

    # Catherine - will have different address, causing review
    @existing_patient_duplicate_review =
      create(
        :patient,
        given_name: "Catherine",
        family_name: "Williams",
        nhs_number: "9876543210",
        date_of_birth: Date.new(2010, 5, 15),
        gender_code: :female,
        address_line_1: "999 Old Street", # Different from CSV
        address_line_2: "",
        address_town: "Birmingham", # Different from CSV
        address_postcode: "B1 1AA", # Different from CSV
        school: nil,
        session: @session
      )

    expect(Patient.count).to eq(3)
  end

  def and_pds_lookup_during_import_is_enabled
    Flipper.enable(:pds_lookup_during_import)

    stub_pds_search_to_return_a_patient(
      "9449306168",
      "family" => "Samson",
      "given" => "Betty",
      "birthdate" => "eq2010-01-01",
      "address-postalcode" => "SW1A 1AA"
    )

    stub_pds_search_to_return_a_patient(
      "9876543210",
      "family" => "Williams",
      "given" => "Catherine",
      "birthdate" => "eq2009-05-15",
      "address-postalcode" => "SW2 2BB"
    )

    stub_pds_search_to_return_a_patient(
      "4491459835",
      "family" => "Brown",
      "given" => "Charlie",
      "birthdate" => "eq2011-03-15",
      "address-postalcode" => "SW2 2BB"
    )
  end

  def when_i_visit_the_import_page
    visit "/"
    click_link "Import", match: :first
  end

  def when_i_go_back_to_the_import_page
    visit "/imports"
    click_link "1 September 2025 at 12:00pm"
  end

  def when_i_click_review
    click_link "Review"
  end

  def and_i_upload_import_file(filename)
    click_button "Import records"
    choose "Child records"
    click_button "Continue"
    attach_file("cohort_import[csv]", "spec/fixtures/cohort_import/#{filename}")
    click_on "Continue"
  end

  def and_i_do_not_see_an_import_review_for_the_first_patient_uploaded_without_nhs_number
    expect(page).not_to have_content("Actions Review SAMSON, Betty")
  end

  def when_i_click_on_the_patient_without_review
    click_link "SAMSON, Betty"
  end

  def then_i_see_an_import_review_for_the_second_patient_uploaded_without_nhs_number
    expect(page).to have_content("Actions Review WILLIAMS, Catherine")
  end

  def when_i_click_on_new_patient_uploaded_without_an_nhs_number
    click_link "BROWN, Charlie"
  end

  def when_i_use_duplicate_record_during_merge
    choose "Use duplicate record"
    click_on "Resolve duplicate"
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def and_i_should_see_one_new_patient_created
    perform_enqueued_jobs
    expect(Patient.count).to eq(4)
  end

  def and_i_see_the_patient_uploaded_with_nhs_number
    expect(page).to have_content(
      "Name and NHS number TWEEDLE, Albert 999 907 5320"
    )
  end

  def then_i_see_the_new_patient_has_an_nhs_number
    expect(page).to have_content("944 930 6168")
    expect(page).to have_content("SAMSON, Betty")
    expect(page).to have_content("1 January 2010 (aged 15)")
  end

  def then_i_see_both_records_have_an_nhs_number
    expect(page).to have_text("987 654 3210", count: 2)
  end

  def then_i_see_the_new_patient_now_has_an_nhs_number
    expect(page).to have_content("NHS number449 145 9835")
    expect(page).to have_content("Full nameBROWN, Charlie")
    expect(page).to have_content("Date of birth15 March 2011 (aged 14)")
  end

  def then_the_existing_patient_has_an_nhs_number_in_mavis
    expect(Patient.count).to eq(4)
    patient = Patient.where(given_name: "Catherine").first
    expect(patient.nhs_number).to eq("9876543210")
    expect(patient.address_line_1).to eq("456 New Street")
    expect(patient.address_town).to eq("London")
    expect(patient.address_postcode).to eq("SW2 2BB")
  end
end
