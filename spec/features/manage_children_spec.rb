# frozen_string_literal: true

describe "Manage children" do
  before { given_my_organisation_exists }

  scenario "Viewing children" do
    given_patients_exist

    when_i_click_on_children
    then_i_see_the_children

    when_i_click_on_a_child
    then_i_see_the_child

    when_i_click_on_activity_log
    then_i_see_the_activity_log
  end

  scenario "Adding an NHS number" do
    given_patients_exist

    when_i_click_on_children
    and_i_click_on_a_child
    then_i_see_the_child

    when_i_click_on_edit_child_record
    then_i_see_the_edit_child_record_page

    when_i_click_on_change_nhs_number
    then_i_see_the_edit_nhs_number_page

    when_i_enter_an_nhs_number
    then_i_see_the_edit_child_record_page
    and_i_see_the_nhs_number

    when_i_click_on_change_nhs_number
    and_i_enter_an_existing_nhs_number
    then_i_see_the_merge_record_page

    when_i_click_on_merge_records
    then_i_see_the_merged_edit_child_record_page
  end

  scenario "Removing a child from a cohort" do
    given_patients_exist
    and_the_patient_belongs_to_a_session

    when_i_click_on_children
    and_i_click_on_a_child
    then_i_see_the_child
    and_i_see_the_cohort

    when_i_click_on_remove_from_cohort
    then_i_see_the_child
    and_i_see_a_removed_from_cohort_message
    and_no_longer_see_the_cohort

    when_i_click_on_children
    and_i_click_on_a_child_who_is_only_in_the_cohort
    when_i_click_on_remove_from_cohort
    then_i_see_the_children
  end

  scenario "Viewing important notices" do
    when_i_click_on_notices
    then_i_see_no_notices

    when_a_deceased_patient_exists
    and_an_invalid_patient_exists
    and_a_restricted_patient_exists
    and_i_click_on_notices
    then_i_see_the_notice_of_date_of_death
    and_i_see_the_notice_of_invalid
    and_i_see_the_notice_of_sensitive
  end

  def given_my_organisation_exists
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
  end

  def given_patients_exist
    school = create(:school, organisation: @organisation)
    @patient =
      create(
        :patient,
        organisation: @organisation,
        given_name: "John",
        family_name: "Smith",
        school:
      )
    create(:vaccination_record, patient: @patient, programme: @programme)
    create_list(:patient, 9, organisation: @organisation, school:)

    @existing_patient =
      create(
        :patient,
        given_name: "Jane",
        family_name: "Doe",
        cohort: @organisation.cohorts.first
      )
  end

  def and_the_patient_belongs_to_a_session
    session =
      create(:session, organisation: @organisation, programme: @programme)
    create(:patient_session, session:, patient: @patient)
  end

  def when_a_deceased_patient_exists
    @deceased_patient = create(:patient, :deceased, organisation: @organisation)
  end

  def and_an_invalid_patient_exists
    @invalidated_patient =
      create(:patient, :invalidated, organisation: @organisation)
  end

  def and_a_restricted_patient_exists
    @restricted_patient =
      create(:patient, :restricted, organisation: @organisation)
  end

  def when_i_click_on_children
    sign_in @organisation.users.first

    visit "/dashboard"
    click_on "Children", match: :first
  end

  def then_i_see_the_children
    expect(page).to have_content(/\d+ children/)
  end

  def when_i_click_on_a_child
    click_on "John Smith"
  end

  alias_method :and_i_click_on_a_child, :when_i_click_on_a_child

  def then_i_see_the_child
    expect(page).to have_title("JS")
    expect(page).to have_content("John Smith")
    expect(page).to have_content("Cohorts")
    expect(page).to have_content("Sessions")
  end

  def when_i_click_on_activity_log
    click_on "Activity log"
  end

  def then_i_see_the_activity_log
    expect(page).to have_content("Added to session")
    expect(page).to have_content("Vaccinated")
  end

  def when_i_click_on_edit_child_record
    click_on "Edit child record"
  end

  def then_i_see_the_edit_child_record_page
    expect(page).to have_title("Edit child record")
    expect(page).to have_content("John Smith")
    expect(page).to have_content("Record details")
  end

  def when_i_click_on_change_nhs_number
    click_on "Change NHS number"
  end
  def then_i_see_the_edit_nhs_number_page
    expect(page).to have_content("What is the child’s NHS number?")
  end

  def when_i_enter_an_nhs_number
    fill_in "What is the child’s NHS number?", with: "123 456 7890"
    click_on "Continue"
  end

  def and_i_enter_an_existing_nhs_number
    fill_in "What is the child’s NHS number?",
            with: @existing_patient.nhs_number
    click_on "Continue"
  end

  def and_i_see_the_nhs_number
    expect(page).to have_content("123 ‍456 ‍7890")
  end

  def then_i_see_the_merge_record_page
    expect(page).to have_content("Do you want to merge this record?")
    expect(page).to have_content("Jane Doe")
  end

  def when_i_click_on_merge_records
    click_on "Merge records"
  end

  def then_i_see_the_merged_edit_child_record_page
    expect(page).to have_title("Edit child record")
    expect(page).to have_content("Jane Doe")
  end

  def and_i_see_the_cohort
    expect(page).not_to have_content("No cohorts")
    expect(page).not_to have_content("No sessions")
  end

  def when_i_click_on_remove_from_cohort
    click_on "Remove from cohort"
  end

  def and_i_see_a_removed_from_cohort_message
    expect(page).to have_content(/removed from Year ([0-9]+) cohort/)
  end

  def and_no_longer_see_the_cohort
    expect(page).to have_content("No cohorts")
    expect(page).to have_content("No sessions")
  end

  def when_i_click_on_notices
    sign_in @organisation.users.first

    visit "/dashboard"
    click_on "Notices"
  end

  alias_method :and_i_click_on_notices, :when_i_click_on_notices

  def then_i_see_no_notices
    expect(page).to have_content("There are currently no important notices.")
  end

  def then_i_see_the_notice_of_date_of_death
    expect(page).to have_content(@deceased_patient.full_name)
    expect(page).to have_content("Record updated with child’s date of death")
  end

  def and_i_see_the_notice_of_invalid
    expect(page).to have_content(@invalidated_patient.full_name)
    expect(page).to have_content("Record flagged as invalid")
  end

  def and_i_see_the_notice_of_sensitive
    expect(page).to have_content(@restricted_patient.full_name)
    expect(page).to have_content("Record flagged as sensitive")
  end

  def and_i_click_on_a_child_who_is_only_in_the_cohort
    click_on "Jane Doe"
  end
end
