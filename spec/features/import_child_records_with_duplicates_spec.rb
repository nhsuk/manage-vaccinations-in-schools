# frozen_string_literal: true

describe "Child record imports duplicates" do
  around do |example|
    # to ensure the age calculation stays correct
    travel_to Time.zone.local(2024, 12, 1) do
      example.run
    end
  end

  scenario "User reviews and selects between duplicate records" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_import_page_with_duplicate_records

    when_i_review_the_first_duplicate_record
    then_i_should_see_the_first_duplicate_record

    when_i_submit_the_form_without_choosing_anything
    then_i_should_see_a_validation_error

    when_i_choose_to_keep_the_duplicate_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_first_duplicate_record_should_be_persisted

    when_i_review_the_second_duplicate_record
    then_i_should_see_the_second_duplicate_record

    when_i_choose_to_keep_the_previously_uploaded_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_second_record_should_not_be_updated

    when_i_review_the_third_duplicate_record
    then_i_should_see_the_third_duplicate_record

    when_i_choose_to_keep_both_records
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_third_record_should_be_persisted
    and_a_new_patient_record_should_be_created

    when_i_go_to_the_programme
    then_i_should_see_no_import_issues_with_the_count
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse)
    sign_in @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    create(
      :organisation_programme,
      organisation: @organisation,
      programme: @programme
    )
    @school = create(:school, urn: "123456", organisation: @organisation)
    @session =
      create(
        :session,
        organisation: @organisation,
        location: @school,
        programme: @programme
      )
  end

  def and_an_existing_patient_record_exists
    @first_patient =
      create(
        :patient,
        given_name: "Jennifer",
        family_name: "Clarke",
        nhs_number: "1234567890", # First row of valid.csv
        date_of_birth: Date.new(2010, 1, 1),
        gender_code: :female,
        address_line_1: "10 Downing Street",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW11 1AA",
        school: nil, # Unknown school, should be silently updated
        organisation: @organisation
      )

    @second_patient =
      create(
        :patient,
        given_name: "James", # The upload will change this to Jimmy
        family_name: "Smith",
        nhs_number: "1234567891", # Second row of valid.csv
        date_of_birth: Date.new(2010, 1, 2),
        gender_code: :male,
        address_line_1: "10 Downing Street",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW11 1AA",
        school: @school,
        organisation: @organisation
      )

    @third_patient =
      create(
        :patient,
        given_name: "Mark", # 3/4 match to third row of valid.csv on first name, last name and postcode
        family_name: "Doe",
        nhs_number: nil,
        date_of_birth: Date.new(2013, 3, 3), # different date of birth
        gender_code: :male,
        address_line_1: "10 Downing Street",
        address_line_2: "",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        school: @school,
        organisation: @organisation,
        session: @session
      )
  end

  def when_i_visit_the_cohort_page_for_the_hpv_programme
    visit "/"
    click_link "Programmes", match: :first
    click_link "HPV"
    click_link "Cohorts"
  end

  def and_i_start_adding_children_to_the_cohort
    click_link "Import child records"
  end

  def and_i_upload_a_file_with_duplicate_records
    attach_file("cohort_import[csv]", "spec/fixtures/cohort_import/valid.csv")
    click_on "Continue"
  end

  def then_i_should_see_the_import_page_with_duplicate_records
    expect(page).to have_content("3 duplicate records need review")
  end

  def when_i_choose_to_keep_the_duplicate_record
    choose "Use duplicate record"
  end

  def when_i_choose_to_keep_both_records
    choose "Keep both records"
  end

  def when_i_choose_to_keep_the_previously_uploaded_record
    choose "Keep previously uploaded record"
  end

  def when_i_submit_the_form_without_choosing_anything
    click_on "Resolve duplicate"
  end
  alias_method :and_i_confirm_my_selection,
               :when_i_submit_the_form_without_choosing_anything

  def then_i_should_see_a_success_message
    expect(page).to have_content("Record updated")
  end

  def when_i_review_the_first_duplicate_record
    click_on "Review CLARKE, Jennifer"
  end

  def then_i_should_see_the_first_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Date of birth1 January 2010 (aged 14)")
    expect(page).to have_content("Address10 Downing StreetLondonSW11 1AA")
    expect(page).to have_content("Address10 Downing StreetLondonSW1A 1AA")
  end

  def then_i_should_see_the_second_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Full nameSMITH, James")
    expect(page).to have_content("Full nameSMITH, Jimmy")
    expect(page).to have_content("Address10 Downing StreetLondonSW11 1AA")
    expect(page).to have_content("Address10 Downing StreetLondonSW1A 1AA")
  end

  def then_i_should_see_a_validation_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_review_the_second_duplicate_record
    click_on "Review SMITH, James"
  end

  def and_the_first_duplicate_record_should_be_persisted
    @first_patient.reload
    expect(@first_patient.given_name).to eq("Jennifer")
    expect(@first_patient.family_name).to eq("Clarke")
    expect(@first_patient.pending_changes).to eq({})
  end

  def and_the_second_record_should_not_be_updated
    @second_patient.reload
    expect(@second_patient.given_name).to eq("James")
    expect(@second_patient.family_name).to eq("Smith")
    expect(@second_patient.pending_changes).to eq({})
  end

  def and_the_third_record_should_be_persisted
    @third_patient.reload
    expect(@third_patient.given_name).to eq("Mark")
    expect(@third_patient.family_name).to eq("Doe")
    expect(@third_patient.pending_changes).to eq({})
  end

  def and_a_new_patient_record_should_be_created
    expect(Patient.count).to eq(4)

    patient = Patient.last
    expect(patient.given_name).to eq("Mark")
    expect(patient.family_name).to eq("Doe")
    expect(patient.pending_changes).to eq({})
    expect(patient.school).to eq(@school)
    expect(patient.date_of_birth).to eq(Date.new(2010, 1, 3))
    expect(patient.gender_code).to eq("male")
    expect(patient.address_postcode).to eq("SW1A 1AA")
    expect(patient.nhs_number).to be_nil
    expect(patient.sessions.count).to eq(1)

    session = patient.sessions.first
    expect(session).to eq(@session)
  end

  def when_i_review_the_third_duplicate_record
    click_on "Review DOE, Mark"
  end

  def then_i_should_see_the_third_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Full nameDOE, Mark")
    expect(page).to have_content("Date of birth3 January 2010 (aged 14)")
    expect(page).to have_content("Date of birth3 March 2013 (aged 11)")
    expect(page).to have_content("Year groupYear 10 (")
    expect(page).to have_content("Year groupYear 7 (")
  end

  def when_i_go_to_the_programme
    click_link "HPV"
  end

  def then_i_should_see_import_issues_with_the_count
    expect(page).to have_link("Import issues")
    expect(page).to have_selector(".app-count", text: "( 1 )")
  end

  def then_i_should_see_no_import_issues_with_the_count
    expect(page).to have_link("Import issues")
    expect(page).to have_selector(".app-count", text: "( 0 )")
  end

  def when_i_go_to_import_issues
    click_link "Import issues"
  end

  def then_i_should_see_that_a_record_needs_review
    expect(page).to have_content("1 imported record needs review")
  end
end
