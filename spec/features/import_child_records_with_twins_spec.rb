# frozen_string_literal: true

describe "Child record imports twins" do
  around { |example| travel_to(Date.new(2024, 12, 1)) { example.run } }

  scenario "User reviews and selects between duplicate records" do
    stub_pds_get_nhs_number_to_return_a_patient
    stub_pds_search_to_return_a_patient

    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_import_page_with_duplicate_records
    then_i_wait_for_the_background_job_to_complete

    when_i_review_the_duplicate_record
    then_i_should_see_the_duplicate_record

    when_i_choose_to_keep_both_records
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_a_new_patient_record_should_be_created
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse)
    sign_in @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    programme = create(:programme, :hpv, organisations: [@organisation])

    @school = create(:school, urn: "123456", organisation: @organisation)
    @session =
      create(
        :session,
        organisation: @organisation,
        location: @school,
        programmes: [programme]
      )
  end

  def and_an_existing_patient_record_exists
    @existing_patient =
      create(
        :patient,
        given_name: "John",
        family_name: "Doe",
        nhs_number: "9000000009",
        date_of_birth: Date.new(2010, 1, 3),
        gender_code: :male,
        address_line_1: "11 Downing Street",
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
    expect(page).to have_content("1 duplicate record needs review")
  end

  def then_i_wait_for_the_background_job_to_complete
    perform_enqueued_jobs
  end

  def when_i_review_the_duplicate_record
    click_on "Review DOE, John"
  end

  def then_i_should_see_the_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("NHS number944 ‍930 ‍6168\nFull nameDOE, Mark")
    expect(page).to have_content("NHS number900 ‍000 ‍0009\nFull nameDOE, John")
  end

  def when_i_choose_to_keep_both_records
    choose "Keep both records"
  end

  def and_i_confirm_my_selection
    click_on "Resolve duplicate"
  end

  def then_i_should_see_a_success_message
    expect(page).to have_content("Record updated")
  end

  def and_a_new_patient_record_should_be_created
    expect(Patient.count).to eq(2)

    patient = Patient.last
    expect(patient.address_postcode).to eq("SW1A 1AA")
    expect(patient.date_of_birth).to eq(Date.new(2010, 1, 3))
    expect(patient.family_name).to eq("Doe")
    expect(patient.gender_code).to eq("male")
    expect(patient.given_name).to eq("Mark")
    expect(patient.nhs_number).to eq("9449306168")
    expect(patient.pending_changes).to eq({})
    expect(patient.school).to eq(@school)
    expect(patient.sessions.count).to eq(2)

    session = patient.sessions.first
    expect(session).to eq(@session)
  end
end
