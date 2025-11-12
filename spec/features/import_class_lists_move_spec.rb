# frozen_string_literal: true

describe "Import class lists - Moving patients" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User uploads a file and moves patients to a new session" do
    given_an_hpv_programme_is_underway

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_select_the_year_groups
    then_i_should_see_the_import_page

    when_i_upload_a_valid_file
    then_i_should_see_the_import_complete_page

    when_i_visit_a_different_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_select_the_year_groups
    and_i_upload_a_valid_file
    then_i_should_see_the_import_complete_page

    when_i_visit_the_school_moves
    then_i_should_see_the_school_moves

    when_i_confirm_a_move
    then_i_should_see_a_success_flash

    when_i_ignore_a_move
    then_i_should_see_a_notice_flash
  end

  context "when PDS lookup during import and import_review_screen is enabled" do
    scenario "User uploads a file and moves patients to a new session" do
      given_an_hpv_programme_is_underway
      and_pds_lookup_during_import_is_enabled
      and_import_review_screen_is_enabled

      when_i_visit_a_session_page_for_the_hpv_programme
      and_i_start_adding_children_to_the_session
      and_i_select_the_year_groups
      then_i_should_see_the_import_page

      when_i_upload_a_valid_file
      then_i_should_see_the_import_complete_page

      when_i_visit_a_different_session_page_for_the_hpv_programme
      and_i_start_adding_children_to_the_session
      and_i_select_the_year_groups
      and_i_upload_a_valid_file
      then_i_should_see_the_import_complete_page

      when_i_visit_the_school_moves
      then_i_should_see_the_school_moves

      when_i_confirm_a_move
      then_i_should_see_a_success_flash

      when_i_ignore_a_move
      then_i_should_see_a_notice_flash
    end
  end

  def given_an_hpv_programme_is_underway
    programmes = [CachedProgramme.hpv]

    @team = create(:team, :with_generic_clinic, :with_one_nurse, programmes:)
    @user = @team.users.first

    location = create(:school, :secondary, name: "Waterloo Road", team: @team)
    other_location =
      create(:school, :secondary, name: "Different Road", team: @team)

    create(:session, :unscheduled, team: @team, location:, programmes:)
    create(
      :session,
      :unscheduled,
      team: @team,
      location: other_location,
      programmes:
    )
  end

  def and_pds_lookup_during_import_is_enabled
    Flipper.enable(:import_search_pds)

    stub_pds_search_to_return_a_patient(
      "9990000026",
      "family" => "Smith",
      "given" => "Jimmy",
      "birthdate" => "eq2010-01-02",
      "address-postalcode" => "SW1A 1AA"
    )

    stub_pds_search_to_return_a_patient(
      "9999075320",
      "family" => "Clarke",
      "given" => "Jennifer",
      "birthdate" => "eq2010-01-01",
      "address-postalcode" => "SW1A 1AA"
    )

    stub_pds_search_to_return_a_patient(
      "9999075320",
      "family" => "Clarke",
      "given" => "Jennifer",
      "birthdate" => "eq2010-01-01",
      "address-postalcode" => "SW1A 1AB"
    )

    stub_pds_search_to_return_a_patient(
      "9435764479",
      "family" => "Doe",
      "given" => "Mark",
      "birthdate" => "eq2010-01-03",
      "address-postalcode" => "SW1A 1AA"
    )
  end

  def and_import_review_screen_is_enabled
    Flipper.enable(:import_review_screen)
  end

  def when_i_visit_a_session_page_for_the_hpv_programme
    sign_in @user
    visit "/dashboard"
    click_on "Sessions", match: :first
    choose "Unscheduled"
    click_on "Update results"
    click_on "Waterloo Road"
  end

  def when_i_visit_a_different_session_page_for_the_hpv_programme
    visit "/dashboard"
    click_on "Sessions", match: :first
    choose "Unscheduled"
    click_on "Update results"
    click_on "Different Road"
  end

  def and_i_start_adding_children_to_the_session
    click_on "Import class lists"
  end

  def and_i_select_the_year_groups
    check "Year 8"
    check "Year 9"
    check "Year 10"
    check "Year 11"
    click_on "Continue"
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Import class list")
  end

  def when_i_upload_a_valid_file
    attach_file("class_import[csv]", "spec/fixtures/class_import/valid.csv")
    click_on "Continue"
    wait_for_import_to_complete(ClassImport)
  end

  alias_method :and_i_upload_a_valid_file, :when_i_upload_a_valid_file

  def when_i_go_to_the_upload_page
    click_on "Import class lists"
  end

  def then_i_should_see_the_import_complete_page
    expect(page).to have_content("Completed")
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported by")
  end

  def when_i_visit_the_school_moves
    click_on "School moves"
  end

  def then_i_should_see_the_school_moves
    expect(page).to have_content("School moves (4)")
    expect(page).to have_content("4 school moves")
  end

  def when_i_confirm_a_move
    click_on "Review", match: :first
    choose "Update record with new school"
    click_on "Update child record"
  end

  def then_i_should_see_a_success_flash
    expect(page).to have_alert("Success")
  end

  def when_i_ignore_a_move
    click_on "Review", match: :first
    choose "Ignore new information"
    click_on "Update child record"
  end

  def then_i_should_see_a_notice_flash
    expect(page).to have_region("Information")
  end
end
