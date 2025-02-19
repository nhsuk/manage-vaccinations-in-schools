# frozen_string_literal: true

describe "Immunisation imports duplicates" do
  scenario "User reviews and selects between duplicate records" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists

    when_i_go_to_the_vaccinations_page
    and_i_click_on_the_upload_link
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_import_page_with_duplicate_records
    and_the_first_patient_should_not_be_updated_but_have_a_vaccination_record

    when_i_review_the_first_duplicate_record
    then_i_should_see_the_first_duplicate_record

    when_i_submit_the_form_without_choosing_anything
    then_i_should_see_a_validation_error

    when_i_choose_to_keep_the_duplicate_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_duplicate_record_should_be_persisted

    when_i_review_the_second_duplicate_record
    then_i_should_see_the_second_duplicate_record

    when_i_choose_to_keep_the_previously_uploaded_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_second_record_should_not_be_updated

    when_i_go_to_the_programme
    then_i_should_see_no_import_issues_with_the_count
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse, ods_code: "R1L")
    sign_in @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv_all_vaccines)
    create(
      :organisation_programme,
      organisation: @organisation,
      programme: @programme
    )
    @location = create(:school, urn: "110158")
    @session =
      create(
        :session,
        organisation: @organisation,
        programme: @programme,
        location: @location,
        date: Date.new(2024, 5, 14)
      )
  end

  def and_an_existing_patient_record_exists
    @existing_patient =
      create(
        :patient,
        given_name: "Esmae",
        family_name: "O'Connell",
        nhs_number: "7420180008", # First row of valid_hpv.csv
        date_of_birth: Date.new(2014, 3, 29),
        gender_code: :female,
        address_postcode: "SW11 1AA",
        school: @location
      )
    @already_vaccinated_patient =
      create(
        :patient,
        given_name: "Caden",
        family_name: "Attwater",
        nhs_number: "4146825652", # Third row of valid_hpv.csv
        date_of_birth: Date.new(2012, 9, 14),
        gender_code: :male,
        address_postcode: "LE1 2DA",
        school: @location
      )
    @third_patient =
      create(
        :patient,
        given_name: "Joanna",
        family_name: "Hamilton",
        nhs_number: "2675725722", # Fourth row of valid_hpv.csv
        date_of_birth: Date.new(2012, 9, 14),
        gender_code: :female,
        address_postcode: "LE8 2DA",
        school: @location
      )
    @patient_session =
      create(
        :patient_session,
        patient: @already_vaccinated_patient,
        session: @session
      )
    @third_patient_session =
      create(:patient_session, patient: @third_patient, session: @session)
    @vaccine = @programme.vaccines.find_by(nivs_name: "Gardasil9")
    @other_vaccine = @programme.vaccines.find_by(nivs_name: "Cervarix")
    @batch = create(:batch, vaccine: @vaccine, name: "SomethingElse")
    @other_batch =
      create(:batch, vaccine: @other_vaccine, name: "CervarixBatch")
    @previous_vaccination_record =
      create(
        :vaccination_record,
        programme: @programme,
        performed_at: @session.dates.min.in_time_zone + 12.hours,
        notes: "Foo",
        created_at: Time.zone.yesterday,
        batch: @batch,
        delivery_method: :nasal_spray,
        delivery_site: :nose,
        dose_sequence: 1,
        patient: @already_vaccinated_patient,
        session: @session,
        vaccine: @vaccine,
        performed_by_user: nil
      )
    @another_previous_vaccination_record =
      create(
        :vaccination_record,
        programme: @programme,
        performed_at: @session.dates.min.in_time_zone + 12.hours,
        notes: "Bar",
        created_at: Time.zone.yesterday,
        batch: @other_batch,
        delivery_method: :nasal_spray,
        delivery_site: :left_arm_upper_position,
        dose_sequence: 1,
        patient: @third_patient,
        session: @session,
        vaccine: @other_vaccine,
        performed_by_user: nil
      )
  end

  def when_i_go_to_the_vaccinations_page
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
  end

  def and_i_click_on_the_upload_link
    click_on "Import vaccination records"
  end

  def and_i_upload_a_file_with_duplicate_records
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_import_page_with_duplicate_records
    expect(page).to have_content("2 duplicate records need review")
  end

  def when_i_choose_to_keep_the_duplicate_record
    choose "Use duplicate record"
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
    click_on "Review ATTWATER, Caden"
  end

  def then_i_should_see_the_first_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Batch ID123013325")
    expect(page).to have_content("Batch IDSomethingElse")
    expect(page).to have_content("MethodIntramuscular")
    expect(page).to have_content("MethodNasal spray")
    expect(page).to have_content("SiteLeft thigh")
    expect(page).to have_content("SiteNose")
  end

  def then_i_should_see_the_second_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Batch ID123013325")
    expect(page).to have_content("Batch IDCervarixBatch")
    expect(page).to have_content("MethodNasal spray")
    expect(page).to have_content("SiteLeft arm (upper position)")
    expect(page).to have_content("SiteNose")
  end

  def and_the_first_patient_should_not_be_updated_but_have_a_vaccination_record
    @existing_patient.reload
    expect(@existing_patient.given_name).to eq("Esmae")
    expect(@existing_patient.family_name).to eq("O'Connell")
    expect(@existing_patient.pending_changes).to eq({})
    expect(@existing_patient.vaccination_records.count).to eq(1)
    vaccs_record = @existing_patient.vaccination_records.first
    expect(vaccs_record.performed_at).to eq(
      Time.new(2024, 5, 14, 12, 0, 0, "+01:00")
    )
    expect(vaccs_record.delivery_method).to eq("intramuscular")
    expect(vaccs_record.delivery_site).to eq("left_buttock")
  end

  def then_i_should_see_a_validation_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_review_the_second_duplicate_record
    click_on "Review HAMILTON, Joanna"
  end

  def and_the_duplicate_record_should_be_persisted
    @previous_vaccination_record.reload
    expect(@previous_vaccination_record.delivery_method).to eq("intramuscular")
    expect(@previous_vaccination_record.delivery_site).to eq("left_thigh")
    expect(@previous_vaccination_record.pending_changes).to eq({})
  end

  def and_the_second_record_should_not_be_updated
    @another_previous_vaccination_record.reload
    expect(@another_previous_vaccination_record.delivery_method).to eq(
      "nasal_spray"
    )
    expect(@another_previous_vaccination_record.delivery_site).to eq(
      "left_arm_upper_position"
    )
    expect(@another_previous_vaccination_record.pending_changes).to eq({})
  end

  def when_i_upload_the_records
    click_button "Upload records"
  end

  def then_i_should_see_the_vaccination_upload_report
    expect(page).to have_content("Vaccination report")
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
