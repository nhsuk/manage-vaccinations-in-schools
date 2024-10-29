# frozen_string_literal: true

describe "Class list imports duplicates" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User reviews and selects between duplicate records" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_existing_patient_records_exist

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_import_page_with_duplicate_records

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

    when_i_choose_to_keep_the_existing_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_second_record_should_not_be_updated
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse)
    sign_in @team.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    create(:team_programme, team: @team, programme: @programme)
    @location =
      create(:location, :secondary, name: "Waterloo Road", team: @team)
    @session =
      create(
        :session,
        :unscheduled,
        team: @team,
        location: @location,
        programme: @programme
      )
  end

  def and_existing_patient_records_exist
    @existing_patient =
      create(
        :patient,
        given_name: "Jimmy",
        family_name: "Smith",
        nhs_number: "9990000016",
        date_of_birth: Date.new(2010, 1, 1),
        gender_code: :male,
        address_postcode: "SW1A 1AA",
        school: @location
      )

    @second_patient =
      create(
        :patient,
        given_name: "Sarah",
        family_name: "Jones",
        nhs_number: "9990000024",
        date_of_birth: Date.new(2010, 2, 2),
        gender_code: :female,
        address_postcode: "SW1A 2BB",
        school: @location
      )
  end

  def when_i_visit_a_session_page_for_the_hpv_programme
    visit "/dashboard"
    click_on "Sessions", match: :first
    click_on "Unscheduled"
    click_on "Waterloo Road"
  end

  def and_i_start_adding_children_to_the_session
    click_on "Import class list"
  end

  def and_i_upload_a_file_with_duplicate_records
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/duplicates.csv"
    )
    click_on "Continue"
    click_link ClassImport.last.created_at.to_fs(:long), match: :first
  end

  def then_i_should_see_the_import_page_with_duplicate_records
    expect(page).to have_content("2 duplicate records need review")
  end

  def when_i_review_the_first_duplicate_record
    click_on "Review Jimmy Smith"
  end

  def then_i_should_see_the_first_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("PostcodeSW1A 1AA")
    expect(page).to have_content("PostcodeSW1A 1BB")
  end

  def when_i_submit_the_form_without_choosing_anything
    click_on "Resolve duplicate"
  end
  alias_method :and_i_confirm_my_selection,
               :when_i_submit_the_form_without_choosing_anything

  def then_i_should_see_a_validation_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_choose_to_keep_the_duplicate_record
    choose "Use duplicate record"
  end

  def when_i_choose_to_keep_the_existing_record
    choose "Keep previously uploaded record"
  end

  def then_i_should_see_a_success_message
    expect(page).to have_content("Record updated")
  end

  def and_the_first_record_should_be_updated
    @existing_patient.reload
    expect(@existing_patient.address_postcode).to eq("SW1A 1BB")
    expect(@existing_patient.pending_changes).to eq({})
  end

  def when_i_review_the_second_duplicate_record
    click_on "Review Sarah Jones"
  end

  def then_i_should_see_the_second_duplicate_record
    expect(page).to have_content("This record needs reviewing")
    expect(page).to have_content("Full nameSara Jones")
    expect(page).to have_content("Full nameSarah Jones")
  end

  def and_the_second_record_should_not_be_updated
    @second_patient.reload
    expect(@second_patient.given_name).to eq("Sarah")
    expect(@second_patient.pending_changes).to eq({})
  end
end
