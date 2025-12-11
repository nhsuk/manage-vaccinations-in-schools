# frozen_string_literal: true

describe "Import class lists" do
  scenario "Single import cancelled at review stage" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_patients_exist
    and_import_review_is_enabled

    when_i_visit_a_school_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_school
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
    and_two_patients_exists_in_the_session
    and_import_review_is_enabled

    when_i_visit_a_school_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_school
    and_i_select_the_year_groups

    when_i_upload_a_valid_file
    then_i_should_see_the_first_import_review_screen
    and_no_patients_from_the_first_import_are_committed

    when_i_visit_a_school_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_school
    and_i_select_the_year_groups
    when_i_upload_another_valid_file
    and_i_approve_the_import
    then_the_patients_from_the_second_import_are_committed

    when_i_go_back_to_the_first_import
    and_i_approve_the_import
    then_i_see_the_import_needs_re_review
    and_a_school_move_for_john_is_created
    and_no_school_move_for_rachel_is_created

    when_i_ignore_changes
    then_the_re_review_patients_are_not_imported
    and_the_import_is_in_re_review_again
    and_there_is_no_option_to_ignore_changes
    and_a_school_move_for_rachel_is_created

    when_i_approve_the_import
    and_i_see_the_import_is_partially_completed
    and_reviewer_details_are_displayed
    and_school_moves_for_all_ignored_records_are_created
  end

  scenario "Import with re-review for school moves out of school only - ignoring changes" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_import_review_is_enabled

    when_i_visit_a_school_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_school
    and_i_select_the_year_groups

    when_i_upload_a_file_with_one_new_patient
    then_i_should_see_the_import_review_screen_with_new_patients_only

    when_a_patient_is_moved_into_the_school

    and_i_approve_the_import
    then_i_see_the_re_review_screen_for_school_moves_out_only
    and_the_new_patient_is_added_to_the_school

    and_i_approve_the_import
    then_the_school_move_out_is_created
  end

  scenario "Import with re-review for school moves out of school only - approving import" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_import_review_is_enabled

    when_i_visit_a_school_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_school
    and_i_select_the_year_groups

    when_i_upload_a_file_with_one_new_patient
    then_i_should_see_the_import_review_screen_with_new_patients_only

    when_a_patient_is_moved_into_the_school

    and_i_approve_the_import
    then_i_see_the_re_review_screen_for_school_moves_out_only
    and_the_new_patient_is_added_to_the_school

    when_i_approve_the_import
    then_the_school_move_out_is_created
  end

  scenario "Import with duplicate resolution in review screen" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_five_patients_exists_in_the_session
    and_import_review_is_enabled
    and_pds_lookup_during_import_is_enabled

    when_i_visit_a_school_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_school
    and_i_select_the_year_groups

    when_i_upload_a_valid_file_with_duplicates
    then_i_should_see_the_import_review_screen_with_issues

    when_i_approve_the_import
    then_i_see_an_error

    when_i_resolve_the_duplicates
    and_i_approve_the_import
    then_i_should_see_the_import_is_successful
    and_patients_are_created_correctly
  end

  def given_i_am_signed_in
    @programme = Programme.hpv
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
    Flipper.enable(:import_handle_issues_in_review)
  end

  def and_pds_lookup_during_import_is_enabled
    Flipper.enable(:import_search_pds)

    stub_pds_search_to_return_no_patients(
      "family" => "Klein",
      "given" => "Callie",
      "birthdate" => "eq2014-11-19",
      "address-postalcode" => "KT2 9HF"
    )
    stub_pds_search_to_return_no_patients(
      "family" => "Klein",
      "given" => "Callie",
      "birthdate" => "eq2014-11-19",
      "address-postalcode" => "KT*"
    )
    stub_pds_search_to_return_no_patients(
      "family" => "Kle*",
      "given" => "Callie",
      "birthdate" => "eq2014-11-19",
      "address-postalcode" => "KT2 9HF"
    )
    stub_pds_search_to_return_no_patients(
      "family" => "Klein",
      "given" => "Cal*",
      "birthdate" => "eq2014-11-19",
      "address-postalcode" => "KT2 9HF"
    )
    stub_pds_search_to_return_a_patient(
      "9435769047",
      "family" => "Lauren",
      "given" => "Ralph",
      "birthdate" => "eq2015-10-14",
      "address-postalcode" => "RH3 1HG"
    )
    stub_pds_search_to_return_a_patient(
      "9435797237",
      "family" => "Kors",
      "given" => "Michael",
      "birthdate" => "eq2015-08-09",
      "address-postalcode" => "OX4 1DY"
    )
    stub_pds_search_to_return_a_patient(
      "9435777066",
      "family" => "Chanel",
      "given" => "Coco",
      "birthdate" => "eq2010-09-10",
      "address-postalcode" => "SW7 5LE"
    )
  end

  def when_i_visit_the_import_page
    visit "/"
    click_link "Import", match: :first
  end

  def when_i_visit_a_school_page_for_the_hpv_programme
    visit "/dashboard"
    click_on "Schools", match: :first
    click_on "Waterloo Road"
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

  def when_i_upload_a_file_with_one_new_patient
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/review_one_new_patient.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete_until_review(ClassImport)
  end

  def when_i_upload_a_valid_file_with_duplicates
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/review_with_duplicates.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete_until_review(ClassImport)
  end

  def when_i_upload_a_valid_file_with_duplicates
    attach_file(
      "class_import[csv]",
      "spec/fixtures/class_import/review_with_duplicates.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete_until_review(ClassImport)
  end

  def and_i_start_adding_children_to_the_school
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
        school: @other_school,
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

  def and_two_patients_exists_in_the_session
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

    # Patient in the session but not in the school, no school move staged
    @stella_mccartney =
      create(
        :patient,
        given_name: "Stella",
        family_name: "Mccartney",
        school: @other_school,
        session: @session
      )

    expect(PatientLocation.where(location: @school).count).to eq(2)
  end

  def when_a_patient_is_moved_into_the_school
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

  def and_five_patients_exists_in_the_session
    and_patients_exist

    create(
      :patient,
      given_name: "Michael",
      family_name: "Kors",
      nhs_number: "9435797237",
      date_of_birth: Date.new(2012, 5, 15),
      gender_code: :male,
      address_line_1: "123 Test way",
      address_line_2: "Example lane",
      address_town: "London",
      address_postcode: "SW1 1AA",
      school: @school,
      registration: nil,
      session: @session,
      birth_academic_year: 12.to_birth_academic_year
    )
  end

  def then_i_should_see_the_import_review_screen
    page.refresh
    click_on_most_recent_import(ClassImport)
    expect(page).to have_content("Review and approve")

    find(".nhsuk-details__summary", text: "1 new record").click
    expect(page).to have_content("KORS, Michael")

    find(".nhsuk-details__summary", text: "3 school moves").click
    expect(page).to have_content("CHANEL, Coco")
    expect(page).to have_content("SMITH, John")
    expect(page).to have_content("KLEIN, Calvin")

    expect(page).to have_content("1 close match to existing records")
    expect(page).to have_content("LAUREN, Ralph")
    expect(page).to have_content("Preferred first nameNot provided Ralphie")

    find(".nhsuk-details__summary", text: "2 records already in Mavis").click
    expect(page).to have_content("KLEIN, Calvin")
    expect(page).to have_content("CHANEL, Coco")

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["in_review"])
  end

  def then_i_should_see_the_first_import_review_screen
    click_on_most_recent_import(ClassImport)
    expect(page).to have_content("Review and approve")

    find(".nhsuk-details__summary", text: "4 new records").click
    expect(page).to have_content("KORS, Michael")
    expect(page).to have_content("LAUREN, Ralph")
    expect(page).to have_content("KLEIN, Calvin")
    expect(page).to have_content("CHANEL, Coco")

    find(".nhsuk-details__summary", text: "1 school move").click
    expect(page).to have_content("SMITH, John")

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["in_review"])
  end

  def then_i_should_see_the_second_import_review_screen
    click_on_most_recent_import(ClassImport)
    expect(page).to have_content("Needs review")

    find(".nhsuk-details__summary", text: "4 new records").click
    expect(page).to have_content("KORS, Michael")
    expect(page).to have_content("LAUREN, Ralph")
    expect(page).to have_content("KLEIN, Calvin")
    expect(page).to have_content("CHANEL, Coco")

    find(".nhsuk-details__summary", text: "1 school move").click
    expect(page).to have_content("SMITH, John")

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["in_review"])
  end

  def then_i_should_see_the_import_review_screen_with_new_patients_only
    visit class_import_path(ClassImport.order(:created_at).last)
    expect(page).to have_content("Review and approve")

    find(".nhsuk-details__summary", text: "1 new record").click
    expect(page).to have_content("KLEIN, Calvin")

    expect(page).not_to have_content("resolve after import")

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["in_review"])
  end

  def then_i_see_the_re_review_screen_for_school_moves_out_only
    visit class_import_path(ClassImport.order(:created_at).last)
    expect(page).to have_content("Further review and approve")

    find(".nhsuk-details__summary", text: "1 school move").click
    expect(page).to have_content("SMITH, John")

    expect(page).not_to have_content("new record")
    expect(page).not_to have_content("close match")
  end

  def then_i_should_see_the_import_review_screen_with_issues
    visit class_import_path(ClassImport.order(:created_at).last)
    expect(page).to have_content("Review and approve")

    expect(page).to have_content("3 close matches to existing records")

    within("tr", text: "KLEIN, Calvin") do
      expect(page).to have_content("First nameCalvin Callie")
      expect(page).to have_content("Use uploaded")
      expect(page).to have_content("Keep existing")
      expect(page).to have_content("Keep both")
    end

    within("tr", text: "LAUREN, Ralph") do
      expect(page).to have_content("RegistrationNot provided Kangaroos")
      expect(page).to have_content("Use uploaded")
      expect(page).to have_content("Keep existing")
      expect(page).not_to have_content("Keep both")
    end

    within("tr", text: "KORS, Michael") do
      expect(page).to have_content("RegistrationNot provided Lion")
      expect(page).to have_content("Use uploaded")
      expect(page).to have_content("Keep existing")
      expect(page).not_to have_content("Keep both")
    end

    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["in_review"])
  end

  def and_the_import_is_in_re_review_again
    wait_for_import_to_complete_until_review(ClassImport)
    visit class_import_path(ClassImport.order(:created_at).first)
    expect(page).to have_content("Further review and approve")

    find(".nhsuk-details__summary", text: "3 school moves").click
    expect(page).to have_content("KLEIN, Calvin")
    expect(page).to have_content("LAUREN, Ralphie")
    expect(page).to have_content("KORS, Michael")
  end

  def and_there_is_no_option_to_ignore_changes
    expect(page).not_to have_button("Ignore changes")
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
    expect(Patient.count).to eq(2)
  end

  alias_method :and_no_patients_from_the_second_import_are_committed,
               :and_no_patients_from_the_first_import_are_committed

  def then_the_patients_from_the_second_import_are_committed
    expect(Patient.count).to eq(6)
    expect(Patient.pluck(:given_name)).to include(
      "Michael",
      "Ralphie",
      "Calvin",
      "Rachel"
    )
  end

  def and_the_new_patient_is_added_to_the_school
    calvin = Patient.find_by(given_name: "Calvin", family_name: "Klein")
    expect(calvin.school).to eq(@school)
  end

  def and_i_can_see_the_import_is_cancelled
    expect(page).to have_content("Cancelled")
    expect(PatientChangeset.all.pluck(:status).uniq).to eq(["cancelled"])
  end

  def when_i_cancel_the_import
    click_on "Cancel and delete upload"
    click_on_most_recent_import(ClassImport)
    perform_enqueued_jobs_while_exists(only: ReviewClassImportSchoolMoveJob)
  end

  def and_i_approve_the_import
    if page.has_button?("Approve and import records")
      click_on("Approve and import records")
    else
      click_on("Approve and import changed records")
    end
    wait_for_import_to_commit(ClassImport)
    perform_enqueued_jobs_while_exists(only: ReviewClassImportSchoolMoveJob)
  end

  alias_method :when_i_approve_the_import, :and_i_approve_the_import

  def when_i_go_back_to_the_first_import
    visit class_import_path(ClassImport.order(:created_at).first)
  end

  def then_i_see_the_import_needs_re_review
    wait_for_import_to_complete_until_review(ClassImport)
    visit class_import_path(ClassImport.order(:created_at).first)
    expect(page).to have_content("Further review and approve")
    expect(ClassImport.first.changesets.processed.count).to eq(2)
    expect(ClassImport.first.changesets.in_review.count).to eq(4)
    expect(ClassImport.first.changesets.from_file.in_review.count).to eq(3)
    expect(ClassImport.first.changesets.not_from_file.in_review.count).to eq(1)
  end

  def and_reviewer_details_are_displayed
    expect(page).to have_content("Approved by\nUSER, Test")
    expect(page).to have_content("Stopped byUSER, Test")
  end

  def and_a_school_move_for_john_is_created
    john = Patient.find_by(given_name: "John", family_name: "Smith")
    expect(john.school_moves.count).to eq(1)
    school_move = john.school_moves.first
    expect(school_move.school_id).to be_nil
  end

  def and_no_school_move_for_rachel_is_created
    rachel = Patient.find_by(given_name: "Rachel", family_name: "Adams")
    expect(rachel.school_moves.count).to eq(0)
  end

  def and_a_school_move_for_rachel_is_created
    rachel = Patient.find_by(given_name: "Rachel", family_name: "Adams")
    expect(rachel.school_moves.count).to eq(1)
    school_move = rachel.school_moves.first
    expect(school_move.school_id).to be_nil
  end

  def and_school_moves_for_all_ignored_records_are_created
    calvin = Patient.find_by(given_name: "Calvin", family_name: "Klein")
    michael = Patient.find_by(given_name: "Michael", family_name: "Kors")
    ralphie = Patient.find_by(given_name: "Ralphie", family_name: "Lauren")

    [calvin, michael, ralphie].each do |patient|
      expect(patient.school_moves.count).to eq(1)
      expect(patient.school_moves.first.school_id).to be_nil
    end
  end

  def then_the_school_move_out_is_created
    john = Patient.find_by(given_name: "John", family_name: "Smith")
    expect(john.school_moves.count).to eq(1)
    school_move = john.school_moves.first
    expect(school_move.school_id).to be_nil
  end

  def when_i_ignore_changes
    click_on "Ignore changes"
    perform_enqueued_jobs_while_exists(only: ReviewClassImportSchoolMoveJob)
  end

  def then_the_re_review_patients_are_not_imported
    expect(Patient.count).to eq(7)
    expect(Patient.with_pending_changes.count).to eq(0)
  end

  def and_i_see_the_import_is_partially_completed
    visit class_import_path(ClassImport.order(:created_at).first)
    expect(page).to have_content("Partially completed")
    expect(page).to have_content("3 records not imported")
  end

  def then_i_see_an_error
    expect(page).to have_content(
      "All records requiring review must have a decision"
    )
  end

  def when_i_resolve_the_duplicates
    visit class_import_path(ClassImport.order(:created_at).first)
    within("tr", text: "KLEIN, Calvin") { choose("Keep both") }

    within("tr", text: "LAUREN, Ralph") { choose("Use uploaded") }

    within("tr", text: "KORS, Michael") { choose("Keep existing") }
  end

  def then_i_should_see_the_import_is_successful
    visit class_import_path(ClassImport.order(:created_at).last)
    expect(page).to have_content("Completed")
    expect(page).not_to have_content("upload issues")
  end

  def and_patients_are_created_correctly
    expect(Patient.count).to eq(6)

    keep_both_old =
      Patient.where(given_name: "Calvin", family_name: "Klein").sole
    keep_both_new =
      Patient.where(given_name: "Callie", family_name: "Klein").sole
    expect(keep_both_old.registration).to be_nil
    expect(keep_both_new.registration).to eq("Kangaroos")
    expect(keep_both_old.school).to eq(@other_school)
    expect(keep_both_new.school).to eq(@other_school)
    expect(keep_both_old.school_moves.count).to eq(0)
    expect(keep_both_new.school_moves.count).to eq(1)
    expect(keep_both_new.school_moves.sole.school_id).to eq(@school.id)
    expect(keep_both_old.parents.count).to eq(0)
    expect(keep_both_new.parents.count).to eq(1)
    expect(keep_both_old.changesets.count).to eq(0)
    expect(keep_both_new.changesets.count).to eq(1)
    expect(keep_both_new.changesets.sole.record_type).to eq("import_issue")
    expect(keep_both_old.pds_search_results.count).to eq(0)
    expect(keep_both_new.pds_search_results.count).to eq(4)

    keep_existing = Patient.find_by(given_name: "Michael", family_name: "Kors")
    expect(keep_existing.registration).to be_nil

    use_uploaded = Patient.find_by(given_name: "Ralph", family_name: "Lauren")
    expect(use_uploaded.registration).to eq("Kangaroos")
  end
end
