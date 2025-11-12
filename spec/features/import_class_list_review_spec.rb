# frozen_string_literal: true

describe "Import class lists" do
  scenario "Single import cancelled at review stage" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_patients_exist
    and_import_review_is_enabled

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_select_the_year_groups

    when_i_upload_a_valid_file
    then_i_should_see_the_import_review_screen
    and_no_changes_are_committed_yet

    when_i_cancel_the_import
    then_no_changes_are_committed_yet
    and_i_can_see_the_import_is_cancelled
  end

  scenario "Two imports in parallel with re-review and partially complete flow" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_one_patient_exists_in_the_school
    and_import_review_is_enabled

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_select_the_year_groups

    when_i_upload_a_valid_file
    then_i_should_see_the_first_import_review_screen
    and_no_patients_from_the_first_import_are_committed

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_select_the_year_groups
    when_i_upload_another_valid_file
    and_i_approve_the_import
    then_the_patients_from_the_second_import_are_committed

    when_i_go_back_to_the_first_import
    and_i_approve_the_import
    then_i_see_the_import_needs_re_review
    and_a_school_move_for_john_is_created

    when_i_ignore_changes
    then_the_re_review_patients_are_not_imported
    and_i_see_the_import_is_partially_completed
  end

  def given_i_am_signed_in
    @programme = CachedProgramme.hpv
    @team = create(:team, :with_one_nurse, programmes: [@programme])

    sign_in @team.users.first
  end

  def and_an_hpv_programme_is_underway
    @school =
      create(
        :school,
        urn: "123456",
        name: "Waterloo Road",
        gias_year_groups: [7, 8, 9, 10],
        team: @team
      )

    @other_school =
      create(
        :school,
        team: @team,
        name: "Liverpool Road",
        gias_year_groups: [7, 8, 9, 10]
      )
    @clinic = create(:generic_clinic, team: @team)

    @session =
      create(:session, team: @team, location: @school, programmes: [@programme])
    @clinic_session =
      create(:session, team: @team, location: @clinic, programmes: [@programme])
    @other_session =
      create(
        :session,
        team: @team,
        location: @other_school,
        programmes: [@programme]
      )
  end

  def and_import_review_is_enabled
    Flipper.enable(:import_review_screen)
  end

  def when_i_visit_the_import_page
    visit "/"
    click_link "Import", match: :first
  end

  def when_i_visit_a_session_page_for_the_hpv_programme
    visit "/dashboard"
    click_on "Sessions", match: :first
    click_on "Waterloo Road"
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

  def when_i_upload_an_invalid_file
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/review_invalid.csv"
    )
    click_on "Continue"
    perform_enqueued_jobs_while_exists(only: ProcessImportJob)
    perform_enqueued_jobs_while_exists(only: ProcessPatientChangesetJob)
    perform_enqueued_jobs_while_exists(only: ReviewPatientChangesetJob)
    perform_enqueued_jobs_while_exists(only: ReviewClassImportSchoolMoveJob)
  end

  def when_i_upload_a_valid_file
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/review_one.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete_until_review(ClassImport)
  end

  def when_i_upload_another_valid_file
    travel_to Time.zone.now + 10.minutes do
      attach_file(
        "class_import[csv]",
        "spec/fixtures/class_import/review_two.csv"
      )
      click_on "Continue"
      wait_for_import_to_complete_until_review(ClassImport)
    end
  end

  def and_i_start_adding_children_to_the_session
    click_on "Import class lists"
  end

  def and_i_select_the_year_groups
    check "Year 8"
    check "Year 9"
    check "Year 10"
    click_on "Continue"
  end

  def and_patients_exist
    @coco_chanel =
      create(
        :patient,
        given_name: "Coco",
        family_name: "Chanel",
        nhs_number: "9435777066",
        date_of_birth: Date.new(2010, 9, 10),
        gender_code: :female,
        address_line_1: "",
        address_line_2: "",
        address_town: "",
        address_postcode: "SW7 5LE",
        school: @other_school,
        registration: nil,
        session: @session
      )

    @ralph_lauren =
      create(
        :patient,
        given_name: "Ralph",
        family_name: "Lauren",
        nhs_number: "9435769047",
        date_of_birth: Date.new(2015, 10, 14),
        gender_code: :male,
        address_line_1: "",
        address_line_2: "",
        address_town: "",
        address_postcode: "OX4 1DY",
        school: @school,
        registration: nil,
        session: @session
      )

    @calvin_klein =
      create(
        :patient,
        given_name: "Calvin",
        family_name: "Klein",
        nhs_number: nil,
        date_of_birth: Date.new(2014, 11, 19),
        gender_code: :male,
        address_line_1: "",
        address_line_2: "",
        address_town: "",
        address_postcode: "KT2 9HF",
        school: @school,
        registration: nil,
        session: @session
      )

    @john_smith =
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        nhs_number: "9435783309",
        date_of_birth: Date.new(2009, 10, 29),
        gender_code: :male,
        address_line_1: "39A Battersea Rise",
        address_line_2: nil,
        address_town: "London",
        address_postcode: "SW1 1AA",
        school: @school,
        registration: nil,
        session: @session
      )
  end

  def and_one_patient_exists_in_the_school
    @john_smith =
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        nhs_number: "9435783309",
        date_of_birth: Date.new(2009, 10, 29),
        gender_code: :male,
        address_line_1: "39A Battersea Rise",
        address_line_2: nil,
        address_town: "London",
        address_postcode: "SW1 1AA",
        school: @school,
        registration: nil,
        session: @session
      )
  end

  def then_i_should_see_the_import_review_screen
    page.refresh
    click_on_most_recent_import(ClassImport)
    expect(page).to have_content("Needs review")

    find(".nhsuk-details__summary", text: "1 new record").click
    expect(page).to have_content("KORS, Michael")

    find(".nhsuk-details__summary", text: "2 school moves").click
    expect(page).to have_content("CHANEL, Coco")
    expect(page).to have_content("SMITH, John")

    find(
      ".nhsuk-details__summary",
      text: "1 close match to existing records"
    ).click
    expect(page).to have_content("LAUREN, Ralph")

    find(".nhsuk-details__summary", text: "2 records already in Mavis").click
    expect(page).to have_content("KLEIN, Calvin")
    expect(page).to have_content("CHANEL, Coco")

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["ready_for_review"])
  end

  def then_i_should_see_the_first_import_review_screen
    click_on_most_recent_import(ClassImport)
    expect(page).to have_content("Needs review")

    find(".nhsuk-details__summary", text: "4 new records").click
    expect(page).to have_content("KORS, Michael")
    expect(page).to have_content("LAUREN, Ralph")
    expect(page).to have_content("KLEIN, Calvin")
    expect(page).to have_content("CHANEL, Coco")

    find(".nhsuk-details__summary", text: "1 school move").click
    expect(page).to have_content("SMITH, John")

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["ready_for_review"])
  end

  def and_no_changes_are_committed_yet
    expect(Patient.count).to eq(4)
    coco = Patient.find_by(given_name: "Coco", family_name: "Chanel")
    expect(coco.school).to eq(@other_school)
    expect(coco.pending_changes).to eq({})
    expect(coco.school_moves.count).to eq(0)

    john = Patient.find_by(given_name: "John", family_name: "Smith")
    expect(john.school).to eq(@school)
    expect(john.school_moves.count).to eq(0)
  end

  alias_method :then_no_changes_are_committed_yet,
               :and_no_changes_are_committed_yet

  def and_no_patients_from_the_first_import_are_committed
    expect(Patient.count).to eq(1)
  end

  def then_the_patients_from_the_second_import_are_committed
    expect(Patient.count).to eq(4)
    expect(Patient.pluck(:given_name)).to include(
      "Michael",
      "Ralphie",
      "Calvin"
    )
  end

  def and_i_can_see_the_import_is_cancelled
    expect(page).to have_content("Cancelled")
    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["cancelled"])
  end

  def when_i_cancel_the_import
    click_on "Cancel and delete upload"
    click_on_most_recent_import(ClassImport)
  end

  def and_i_approve_the_import
    click_on "Approve and import records"
    wait_for_import_to_commit(ClassImport)
  end

  def when_i_go_back_to_the_first_import
    visit class_import_path(ClassImport.order(:created_at).first)
  end

  def then_i_see_the_import_needs_re_review
    wait_for_import_to_complete_until_review(ClassImport)
    visit class_import_path(ClassImport.order(:created_at).first)
    expect(page).to have_content("Needs re-review")
    expect(ClassImport.first.changesets.processed.count).to eq(1)
    expect(ClassImport.first.changesets.ready_for_review.count).to eq(4)
    expect(ClassImport.first.changesets.from_file.ready_for_review.count).to eq(
      3
    )
  end

  def and_a_school_move_for_john_is_created
    john = Patient.find_by(given_name: "John", family_name: "Smith")
    expect(john.school_moves.count).to eq(1)
    school_move = john.school_moves.first
    expect(school_move.school_id).to be_nil
  end

  def when_i_ignore_changes
    click_on "Ignore changes"
  end

  def then_the_re_review_patients_are_not_imported
    expect(Patient.count).to eq(5)
    expect(Patient.with_pending_changes.count).to eq(0)
  end

  def and_i_see_the_import_is_partially_completed
    visit class_import_path(ClassImport.order(:created_at).first)
    expect(page).to have_content("Partially completed")
    expect(page).to have_content("3 records not imported")
  end
end
