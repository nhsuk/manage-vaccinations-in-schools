# frozen_string_literal: true

describe "Immunisation imports duplicates" do
  scenario "User reviews and selects between duplicate records" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists

    when_i_go_to_the_vaccinations_page
    and_i_click_on_the_upload_link
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_edit_page_with_duplicate_records

    when_i_review_the_first_duplicate_record
    then_i_should_see_the_first_duplicate_record

    when_i_submit_the_form_without_choosing_anything
    then_i_should_see_a_validation_error

    when_i_choose_to_keep_the_duplicate_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_first_record_should_be_updated

    when_i_review_the_second_duplicate_record
    then_i_should_see_the_second_duplicate_record

    when_i_choose_to_keep_the_duplicate_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_second_record_should_be_updated

    when_i_upload_the_records
    then_i_should_see_the_vaccination_upload_report

    when_i_go_to_the_programme
    then_i_should_see_import_issues_with_the_count

    when_i_go_to_import_issues
    then_i_should_see_that_a_record_needs_review

    when_i_review_the_third_duplicate_record
    then_i_should_see_the_third_duplicate_record

    when_i_choose_to_keep_the_duplicate_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_third_record_should_be_updated
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv_all_vaccines)
    create(:team_programme, team: @team, programme: @programme)
    @location = create(:location, :school, urn: "110158")
    @session =
      create(
        :session,
        team: @team,
        programme: @programme,
        location: @location,
        date: Date.new(2024, 5, 14)
      )
  end

  def and_an_existing_patient_record_exists
    @existing_patient =
      create(
        :patient,
        first_name: "Esmae",
        last_name: "O'Connell",
        nhs_number: "7420180008", # First row of valid_hpv.csv
        date_of_birth: Date.new(2014, 3, 29),
        gender_code: :female,
        address_postcode: "QG53 3OA",
        school: @location
      )
    @already_vaccinated_patient =
      create(
        :patient,
        first_name: "Caden",
        last_name: "Attwater",
        nhs_number: "4146825652", # Third row of valid_hpv.csv
        date_of_birth: Date.new(2012, 9, 14),
        gender_code: :male,
        address_postcode: "LE1 2DA",
        school: @location
      )
    @third_patient =
      create(
        :patient,
        first_name: "Joanna",
        last_name: "Hamilton",
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
    @vaccine = @programme.vaccines.find_by(nivs_name: "Gardasil9")
    @batch =
      create(
        :batch,
        vaccine: @vaccine,
        expiry: Date.new(2024, 7, 30),
        name: "Something else"
      )
    @previous_vaccination_record =
      create(
        :vaccination_record,
        programme: @programme,
        administered_at: @session.dates.first.value.in_time_zone + 12.hours,
        notes: "Foo",
        recorded_at: Time.zone.yesterday,
        batch: @batch,
        delivery_method: :nasal_spray,
        delivery_site: :nose,
        dose_sequence: 1,
        patient_session: @patient_session,
        vaccine: @vaccine
      )
  end

  def when_i_go_to_the_vaccinations_page
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations"
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
    perform_enqueued_jobs
    click_link ImmunisationImport.last.created_at.to_fs(:long), match: :first
  end

  def then_i_should_see_the_edit_page_with_duplicate_records
    expect(page).to have_content("3 duplicate records need review")
  end

  def when_i_choose_to_keep_the_duplicate_record
    choose "Use duplicate record"
  end

  def when_i_submit_the_form_without_choosing_anything
    click_on "Resolve duplicate"
  end
  alias_method :and_i_confirm_my_selection,
               :when_i_submit_the_form_without_choosing_anything

  def then_i_should_see_a_success_message
    expect(page).to have_content("Vaccination record updated")
  end

  def when_i_review_the_first_duplicate_record
    click_on "Review Esmae O'Connell"
  end

  def then_i_should_see_the_first_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("PostcodeLE3 2DA")
    expect(page).to have_content("PostcodeQG53 3OA")
  end

  def then_i_should_see_the_second_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("MethodIntramuscular")
    expect(page).to have_content("MethodNasal spray")
  end

  def and_the_first_record_should_be_updated
    @existing_patient.reload
    expect(@existing_patient.first_name).to eq("Chyna")
    expect(@existing_patient.last_name).to eq("Pickle")
    expect(@existing_patient.pending_changes).to eq({})
  end

  def then_i_should_see_a_validation_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_review_the_second_duplicate_record
    click_on "Review Caden Attwater"
  end

  def and_the_second_record_should_be_updated
    @previous_vaccination_record.reload
    expect(@previous_vaccination_record.delivery_method).to eq("intramuscular")
    expect(@previous_vaccination_record.delivery_site).to eq("left_thigh")
    expect(@previous_vaccination_record.pending_changes).to eq({})
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

  def when_i_go_to_import_issues
    click_link "Import issues"
  end

  def then_i_should_see_that_a_record_needs_review
    expect(page).to have_content("1 imported record needs review")
  end

  def when_i_review_the_third_duplicate_record
    click_on "Review Joanna Hamilton"
  end

  def then_i_should_see_the_third_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Full nameBerry Hamilton")
    expect(page).to have_content("Full nameJoanna Hamilton")
  end

  def and_the_third_record_should_be_updated
    @third_patient.reload
    expect(@third_patient.first_name).to eq("Berry")
    expect(@third_patient.last_name).to eq("Hamilton")
    expect(@third_patient.pending_changes).to eq({})
  end
end
