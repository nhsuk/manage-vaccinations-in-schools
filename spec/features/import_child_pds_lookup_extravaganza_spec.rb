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
    and_i_should_see_correct_patient_counts

    # Case 1: Patient with existing NHS number (Albert) - nothing should happen
    and_i_see_the_patient_uploaded_with_nhs_number
    and_parents_are_created_for_albert

    # Case 2: Existing patient without NHS number (Betty) - should not show duplicate review
    and_i_do_not_see_an_import_review_for_the_first_patient_uploaded_without_nhs_number
    when_i_click_on_the_patient_without_review
    then_i_see_the_new_patient_has_an_nhs_number
    and_betty_has_correct_parent_relationships

    # Case 3: Existing patient with NHS number (Catherine) - should show duplicate review
    when_i_go_back_to_the_import_page
    then_i_see_an_import_review_for_the_second_patient_uploaded_without_nhs_number
    when_i_click_review_for("WILLIAMS, Catherine")
    then_i_see_both_records_have_an_nhs_number
    and_i_see_address_differences_for_review
    when_i_use_duplicate_record_during_merge
    then_the_existing_patient_has_an_nhs_number_in_mavis
    and_catherine_parents_are_handled_correctly

    # Case 4: New patient without NHS number (Charlie) - should be created with NHS number from PDS
    when_i_go_back_to_the_import_page
    when_i_click_on_new_patient_uploaded_without_an_nhs_number
    then_i_see_the_new_patient_now_has_an_nhs_number
    and_charlie_has_no_parents_as_expected

    # Case 5: Home educated patient (Emma) - test school move handling
    when_i_go_back_to_the_import_page
    when_i_click_on_home_educated_patient
    then_i_see_home_educated_patient_details
    and_emma_has_correct_parent_data

    # Case 6: Patient with parent but no relationship specified (Oliver)
    when_i_go_back_to_the_import_page
    when_i_click_on_patient_with_unknown_relationship
    then_i_see_patient_with_unknown_relationship_details
    and_oliver_has_unknown_relationship_parent

    # Case 7: Patient that matches existing exactly (Oliver)
    when_i_go_back_to_the_import_page
    then_i_see_one_record_is_an_exact_match

    # Case 8: Patient uploaded with incorrect NHS number (Lucy)
    when_i_go_back_to_the_import_page
    then_i_see_an_nhs_discrepancy
    and_lucy_has_the_pds_nhs_number

    # Case 9: Patient uploaded with NHS number, PDS returns nothing (Maia) - patient created with uploaded number
    and_there_is_an_import_review_for_maia
    when_i_review_and_accept_duplicate_maia_record
    then_maia_has_the_uploaded_nhs_number

    then_school_moves_are_created_appropriately

    and_all_parent_relationships_are_established
    and_import_counts_are_correct
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
    @clinic = create(:generic_clinic, team: @team)

    @session =
      create(:session, team: @team, location: @school, programmes: [@programme])
    @clinic_session =
      create(:session, team: @team, location: @clinic, programmes: [@programme])
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

    @different_school = create(:school, urn: "456789", team: @team)
    @different_school_session =
      create(
        :session,
        team: @team,
        location: @different_school,
        programmes: [@programme]
      )

    # Catherine - will have different address and school, causing review, and school move
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
        school: @different_school,
        session: @different_school_session
      )

    @existing_parent =
      create(
        :parent,
        full_name: "John Tweedle",
        email: "john.tweedle@email.com"
      )
    create(
      :parent_relationship,
      parent: @existing_parent,
      patient: @existing_patient_uploaded_with_nhs_number,
      type: "unknown"
    )

    create(:parent, full_name: "David Williams", email: "david.w@email.com")

    @existing_exact_match =
      create(
        :patient,
        given_name: "Lara",
        family_name: "Williams",
        nhs_number: "9435714463",
        date_of_birth: Date.new(2010, 5, 15),
        gender_code: :female,
        address_line_1: "",
        address_line_2: "",
        address_town: "",
        address_postcode: "B1 1AA",
        school: @school,
        session: @session
      )

    @existing_patient_duplicate_review_on_demographics =
      create(
        :patient,
        given_name: "Maia",
        family_name: "Smith",
        nhs_number: nil,
        date_of_birth: Date.new(2010, 8, 15), # Different from CSV
        gender_code: :female,
        address_line_1: "999 Old Street", # Different from CSV
        address_line_2: "",
        address_town: "Birmingham", # Different from CSV
        address_postcode: "W2 3PE",
        school: nil,
        session: @session
      )

    expect(Patient.count).to eq(5)
    expect(ParentRelationship.count).to eq(1)
    expect(Parent.count).to eq(2)
  end

  def and_pds_lookup_during_import_is_enabled
    Flipper.enable(:pds_lookup_during_import)

    stub_pds_search_to_return_a_patient(
      "9999075320",
      "family" => "Tweedle",
      "given" => "Albert",
      "birthdate" => "eq2009-12-29",
      "address-postalcode" => "SW11 1EH"
    )

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

    stub_pds_search_to_return_a_patient(
      "9435783309",
      "family" => "Homeschool",
      "given" => "Emma",
      "birthdate" => "eq2010-06-01",
      "address-postalcode" => "SW3 3AA"
    )

    stub_pds_search_to_return_a_patient(
      "9435714463",
      "family" => "Williams",
      "given" => "Lara",
      "birthdate" => "eq2010-05-15",
      "address-postalcode" => "B1 1AA"
    )

    stub_pds_search_to_return_a_patient(
      "9435753868",
      "family" => "Green",
      "given" => "Oliver",
      "birthdate" => "eq2010-08-15",
      "address-postalcode" => "SW1W 8JL"
    )

    stub_pds_search_to_return_a_patient(
      "9435792170",
      "family" => "McCarthy",
      "given" => "Lucy",
      "birthdate" => "eq2010-08-16",
      "address-postalcode" => "SW7 5LE"
    )

    stub_pds_search_to_return_no_patients(
      "family" => "Smith",
      "given" => "Maia",
      "birthdate" => "eq2010-08-16",
      "address-postalcode" => "W2 3PE"
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

  def when_i_click_review_for(name)
    within(
      :xpath,
      "//div[h3[contains(text(), 'records with import issues')]]"
    ) do
      within(:xpath, ".//tr[contains(., '#{name}')]") { click_link "Review" }
    end
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
    expect(page).to have_content("Matched on NHS number.")
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
    expect(Patient.count).to eq(9)
    patient = Patient.where(given_name: "Catherine").first
    expect(patient.nhs_number).to eq("9876543210")
    expect(patient.address_line_1).to eq("456 New Street")
    expect(patient.address_town).to eq("London")
    expect(patient.address_postcode).to eq("SW2 2BB")
  end

  def and_i_should_see_correct_patient_counts
    perform_enqueued_jobs
    expect(Patient.count).to eq(9)
  end

  def and_parents_are_created_for_albert
    albert = Patient.find_by(given_name: "Albert", family_name: "Tweedle")
    expect(albert.parents.count).to eq(2)
    expect(albert.parents.map(&:full_name)).to contain_exactly(
      "John Tweedle",
      "Mary Tweedle"
    )
    expect(albert.parents.find_by(full_name: "John Tweedle").email).to eq(
      "john.tweedle@email.com"
    )
  end

  def and_betty_has_correct_parent_relationships
    betty = Patient.find_by(given_name: "Betty", family_name: "Samson")
    expect(betty.parent_relationships.count).to eq(2)

    dad_relationship =
      betty
        .parent_relationships
        .joins(:parent)
        .find_by(parents: { full_name: "Robert Samson" })
    expect(dad_relationship.type).to eq("father")

    mum_relationship =
      betty
        .parent_relationships
        .joins(:parent)
        .find_by(parents: { full_name: "Linda Samson" })
    expect(mum_relationship.type).to eq("mother")

    linda = Parent.find_by(full_name: "Linda Samson")
    expect(linda.phone).to be_blank
    expect(linda.phone_receive_updates).to be false
  end

  def and_i_see_address_differences_for_review
    expect(page).to have_content("999 Old Street") # Original address
    expect(page).to have_content("456 New Street") # New address from CSV
    expect(page).to have_content("Birmingham") # Original town
    expect(page).to have_content("London") # New town from CSV
  end

  def and_catherine_parents_are_handled_correctly
    catherine =
      Patient.find_by(given_name: "Catherine", family_name: "Williams")
    expect(catherine.parents.count).to eq(1)

    guardian = catherine.parents.find_by(full_name: "David Williams")
    guardian_relationship =
      catherine.parent_relationships.find_by(parent: guardian)
    expect(guardian_relationship.type).to eq("guardian")
  end

  def and_charlie_has_no_parents_as_expected
    charlie = Patient.find_by(given_name: "Charlie", family_name: "Brown")
    expect(charlie.parents.count).to eq(0)
    expect(charlie.parent_relationships.count).to eq(0)
  end

  def when_i_click_on_home_educated_patient
    click_link "HOMESCHOOL, Emma"
  end

  def then_i_see_home_educated_patient_details
    expect(page).to have_content("HOMESCHOOL, Emma")
    expect(page).to have_content("1 June 2010")
  end

  def and_emma_has_correct_parent_data
    emma = Patient.find_by(given_name: "Emma", family_name: "Homeschool")
    expect(emma.parents.count).to eq(1)

    father = emma.parents.first
    expect(father.full_name).to eq("Mike HomeDad")
    expect(father.email).to eq("mike@home.com")

    relationship = emma.parent_relationships.first
    expect(relationship.type).to eq("father")
  end

  def then_school_moves_are_created_appropriately
    perform_enqueued_jobs

    charlie = Patient.find_by(given_name: "Charlie")
    charlie_move = SchoolMoveLogEntry.find_by(patient: charlie)
    expect(charlie_move).to be_present
    expect(charlie_move.school).to eq(@school)

    emma = Patient.find_by(given_name: "Emma")
    emma_move = SchoolMoveLogEntry.find_by(patient: emma)
    expect(emma_move).to be_present
    expect(emma_move.home_educated).to be true
    expect(emma_move.school).to be_nil

    catherine =
      Patient.find_by(given_name: "Catherine", family_name: "Williams")
    catherine_move = SchoolMove.find_by(patient: catherine, school: @school)
    expect(catherine_move).to be_present
    catherine_log_entry = SchoolMoveLogEntry.find_by(patient: catherine)
    expect(catherine_log_entry).to be_nil
    expect(catherine.school).to eq(@different_school)
  end

  def and_all_parent_relationships_are_established
    expect(Parent.count).to eq(7)
    expect(ParentRelationship.count).to eq(7)

    father_relationships = ParentRelationship.where(type: "father")
    expect(father_relationships.count).to eq(3) # John Tweedle, Mike HomeDad, Robert Samson

    mother_relationships = ParentRelationship.where(type: "mother")
    expect(mother_relationships.count).to eq(2) # Mary Tweedle, Linda Samson

    guardian_relationships = ParentRelationship.where(type: "guardian")
    expect(guardian_relationships.count).to eq(1) # David Williams

    unknown_relationships = ParentRelationship.where(type: "unknown")
    expect(unknown_relationships.count).to eq(1) # Jane Doe
  end

  def and_import_counts_are_correct
    import = CohortImport.last
    expect(import.patients.count).to eq(9)
  end

  def when_i_click_on_patient_with_unknown_relationship
    click_link "GREEN, Oliver"
  end

  def then_i_see_patient_with_unknown_relationship_details
    expect(page).to have_content("GREEN, Oliver")
    expect(page).to have_content("15 August 2010")
  end

  def and_oliver_has_unknown_relationship_parent
    oliver = Patient.find_by(given_name: "Oliver", family_name: "Green")
    expect(oliver.parents.count).to eq(1)

    parent = oliver.parents.first
    expect(parent.full_name).to eq("Jane Doe")
    expect(parent.email).to be_blank

    relationship = oliver.parent_relationships.first
    expect(relationship.type).to eq("unknown")
    expect(relationship.label).to eq("Unknown")
  end
  def when_i_click_on_patient_with_unknown_relationship
    click_link "GREEN, Oliver"
  end

  def then_i_see_patient_with_unknown_relationship_details
    expect(page).to have_content("GREEN, Oliver")
    expect(page).to have_content("15 August 2010")
  end

  def and_oliver_has_unknown_relationship_parent
    oliver = Patient.find_by(given_name: "Oliver", family_name: "Green")
    expect(oliver.parents.count).to eq(1)

    parent = oliver.parents.first
    expect(parent.full_name).to eq("Jane Doe")
    expect(parent.email).to be_blank

    relationship = oliver.parent_relationships.first
    expect(relationship.type).to eq("unknown")
    expect(relationship.label).to eq("Unknown")
  end

  def then_i_see_one_record_is_an_exact_match
    expect(page).to have_content(
      "1 record was not imported because it already exists in Mavis"
    )
  end

  def then_i_see_an_nhs_discrepancy
    expect(page).to have_content("1 NHS number was updated")
  end

  def and_lucy_has_the_pds_nhs_number
    lucy = Patient.find_by(given_name: "Lucy", family_name: "McCarthy")
    expect(lucy.nhs_number).to eq("9435792170")
  end

  def and_there_is_an_import_review_for_maia
    expect(page).to have_content("Actions Review SMITH, Maia")
    expect(page).to have_content("Possible match found. Review and confirm.")
  end

  def when_i_review_and_accept_duplicate_maia_record
    click_link "Review"
    choose "Use duplicate record"
    click_on "Resolve duplicate"
  end

  def then_maia_has_the_uploaded_nhs_number
    maia = Patient.find_by(given_name: "Maia", family_name: "Smith")
    expect(maia.nhs_number).to eq("9435789102")
  end
end
