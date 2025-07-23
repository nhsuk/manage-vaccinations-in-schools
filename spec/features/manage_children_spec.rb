# frozen_string_literal: true

describe "Manage children" do
  before { given_my_organisation_exists }

  scenario "Viewing children" do
    given_patients_exist
    and_the_patient_is_vaccinated

    when_i_click_on_children
    then_i_see_the_children

    when_i_click_on_a_child
    then_i_see_the_child

    when_i_click_on_activity_log
    then_i_see_the_activity_log
  end

  scenario "Adding an NHS number" do
    given_patients_exist
    and_sync_vaccination_records_to_nhs_feature_is_enabled
    and_the_patient_is_vaccinated

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

    when_i_wait_for_the_sync_to_complete
    then_the_vaccination_record_is_created_with_the_nhs

    when_i_click_on_change_nhs_number
    and_i_enter_an_existing_nhs_number
    then_i_see_the_merge_record_page

    when_i_click_on_merge_records
    then_i_see_the_merged_edit_child_record_page
    and_the_vaccination_record_is_updated_with_the_nhs
  end

  scenario "Adding an NHS number to an invalidated patient" do
    given_an_invalidated_patient_exists

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
    and_the_patient_is_no_longer_invalidated
  end

  scenario "Removing an NHS number" do
    given_patients_exist
    and_sync_vaccination_records_to_nhs_feature_is_enabled
    and_the_patient_is_vaccinated
    and_the_vaccination_has_been_synced_to_nhs

    when_i_click_on_children
    and_i_click_on_a_child
    then_i_see_the_child

    when_i_click_on_edit_child_record
    then_i_see_the_edit_child_record_page

    when_i_click_on_change_nhs_number
    then_i_see_the_edit_nhs_number_page

    when_i_enter_a_blank_nhs_number
    then_i_see_the_edit_child_record_page
    and_i_see_the_blank_nhs_number
    and_the_vaccination_record_is_deleted_from_the_nhs
  end

  scenario "Removing a child from a cohort" do
    given_patients_exist

    when_i_click_on_children
    and_i_click_on_a_child
    then_i_see_the_child
    and_i_see_the_cohort

    when_i_click_on_remove_from_cohort
    then_i_see_the_children
    and_i_see_a_removed_from_cohort_message
  end

  scenario "Viewing important notices" do
    when_i_go_to_the_imports_page
    then_i_cannot_see_notices

    when_i_go_to_the_notices_page
    then_i_see_permission_denied
  end

  scenario "Viewing deceased patient notices as a superuser" do
    when_i_go_to_the_imports_page_as_a_superuser
    and_i_click_on_notices
    then_i_see_no_notices

    when_a_deceased_patient_exists
    and_i_click_on_notices
    then_i_see_the_notice_of_date_of_death
  end

  scenario "Viewing invalidated patient notices as a superuser" do
    when_i_go_to_the_imports_page_as_a_superuser
    and_i_click_on_notices
    then_i_see_no_notices

    when_an_invalidated_patient_exists
    and_i_click_on_notices
    then_i_see_the_notice_of_invalid
  end

  scenario "Viewing restricted patient notices as a superuser" do
    when_i_go_to_the_imports_page_as_a_superuser
    and_i_click_on_notices
    then_i_see_no_notices

    when_a_restricted_patient_exists
    and_i_click_on_notices
    then_i_see_the_notice_of_sensitive
  end

  def given_my_organisation_exists
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
  end

  def given_patients_exist
    school = create(:school, organisation: @organisation)

    @session =
      create(
        :session,
        location: school,
        organisation: @organisation,
        programmes: [@programme]
      )

    @patient =
      create(
        :patient,
        session: @session,
        given_name: "John",
        family_name: "Smith",
        school:
      )
    create_list(:patient, 9, session: @session)

    another_session =
      create(:session, organisation: @organisation, programmes: [@programme])

    @existing_patient =
      create(
        :patient,
        session: another_session,
        given_name: "Jane",
        family_name: "Doe"
      )
  end

  def given_an_invalidated_patient_exists
    session =
      create(:session, organisation: @organisation, programmes: [@programme])

    @patient =
      create(
        :patient,
        :invalidated,
        session:,
        given_name: "John",
        family_name: "Smith"
      )

    create(:patient, session:, nhs_number: nil)
  end

  def and_the_patient_is_vaccinated
    create(
      :vaccination_record,
      patient: @patient,
      programme: @programme,
      session: @session
    )
  end

  def and_sync_vaccination_records_to_nhs_feature_is_enabled
    Flipper.enable(:enqueue_sync_vaccination_records_to_nhs)
    Flipper.enable(:immunisations_fhir_api_integration)

    immunisation_uuid = Random.uuid
    @stubbed_post_request = stub_immunisations_api_post(uuid: immunisation_uuid)
    @stubbed_put_request = stub_immunisations_api_put(uuid: immunisation_uuid)
    @stubbed_delete_request =
      stub_immunisations_api_delete(uuid: immunisation_uuid)
  end

  def and_the_vaccination_has_been_synced_to_nhs
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
  end

  def when_a_deceased_patient_exists
    session =
      create(:session, organisation: @organisation, programmes: [@programme])

    @deceased_patient = create(:patient, :deceased, session:)
  end

  def when_an_invalidated_patient_exists
    session =
      create(:session, organisation: @organisation, programmes: [@programme])

    @invalidated_patient = create(:patient, :invalidated, session:)
  end

  def when_a_restricted_patient_exists
    session =
      create(:session, organisation: @organisation, programmes: [@programme])

    @restricted_patient = create(:patient, :restricted, session:)
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
    click_on "SMITH, John"
  end

  alias_method :and_i_click_on_a_child, :when_i_click_on_a_child

  def then_i_see_the_child
    expect(page).to have_title("JS")
    expect(page).to have_content("SMITH, John")
    expect(page).to have_content("Cohorts")
    expect(page).to have_content("Sessions")
  end

  def when_i_click_on_activity_log
    click_on "Activity log"
  end

  def then_i_see_the_activity_log
    expect(page).to have_content("Added to the session")
    expect(page).to have_content("Vaccinated")
  end

  def when_i_click_on_edit_child_record
    click_on "Edit child record"
  end

  def then_i_see_the_edit_child_record_page
    expect(page).to have_title("Edit child record")
    expect(page).to have_content("SMITH, John")
    expect(page).to have_content("Change")
  end

  def when_i_click_on_change_nhs_number
    click_on "Change NHS number"
  end
  def then_i_see_the_edit_nhs_number_page
    expect(page).to have_content("What is the child’s NHS number?")
  end

  def when_i_enter_an_nhs_number
    fill_in "What is the child’s NHS number?", with: "975 862 3168"
    click_on "Continue"
  end

  def when_i_enter_a_blank_nhs_number
    fill_in "What is the child’s NHS number?", with: ""
    click_on "Continue"
  end

  def and_i_enter_an_existing_nhs_number
    fill_in "What is the child’s NHS number?",
            with: @existing_patient.nhs_number
    click_on "Continue"
  end

  def and_i_see_the_nhs_number
    expect(page).to have_content("975 ‍862 ‍3168")
  end

  def and_the_patient_is_no_longer_invalidated
    expect(@patient.reload).not_to be_invalidated
  end

  def and_i_see_the_blank_nhs_number
    expect(page).to have_content("NHS numberNot provided")
  end

  def then_i_see_the_merge_record_page
    expect(page).to have_content("Do you want to merge this record?")
    expect(page).to have_content("DOE, Jane")
  end

  def when_i_click_on_merge_records
    click_on "Merge records"
  end

  def then_i_see_the_merged_edit_child_record_page
    expect(page).to have_title("Edit child record")
    expect(page).to have_content("DOE, Jane")
  end

  def and_i_see_the_cohort
    expect(page).not_to have_content("No cohorts")
    expect(page).not_to have_content("No sessions")
  end

  def when_i_click_on_remove_from_cohort
    click_on "Remove from cohort"
  end

  def and_i_see_a_removed_from_cohort_message
    expect(page).to have_content("removed from cohort")
  end

  def when_i_go_to_the_dashboard
    sign_in @organisation.users.first

    visit "/dashboard"
  end

  def when_i_go_to_the_imports_page
    sign_in @organisation.users.first

    visit "/imports"
  end

  def when_i_go_to_the_imports_page_as_a_superuser
    sign_in @organisation.users.first, superuser: true

    visit "/imports"
  end

  def when_i_wait_for_the_sync_to_complete
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
  end

  def then_i_cannot_see_notices
    expect(page).not_to have_content("Notices")
  end

  def when_i_go_to_the_notices_page
    visit "/imports/notices"
  end

  def then_i_see_permission_denied
    expect(page.status_code).to eq(403)
  end

  def when_i_click_on_notices
    click_on "Important notices"
  end

  alias_method :and_i_click_on_notices, :when_i_click_on_notices

  def then_i_see_no_notices
    expect(page).to have_content("There are currently no important notices.")
  end

  def then_i_see_the_notice_of_date_of_death
    expect(page).to have_content("Important notices ( 1 )")
    expect(page).to have_content(@deceased_patient.full_name)
    expect(page).to have_content("Record updated with child’s date of death")
  end

  def then_i_see_the_notice_of_invalid
    expect(page).to have_content("Important notices ( 1 )")
    expect(page).to have_content(@invalidated_patient.full_name)
    expect(page).to have_content("Record flagged as invalid")
  end

  def then_i_see_the_notice_of_sensitive
    expect(page).to have_content("Important notices ( 1 )")
    expect(page).to have_content(@restricted_patient.full_name)
    expect(page).to have_content("Record flagged as sensitive")
  end

  def then_the_vaccination_record_is_created_with_the_nhs
    expect(@stubbed_post_request).to have_been_requested
  end

  def and_the_vaccination_record_is_updated_with_the_nhs
    perform_enqueued_jobs
    expect(@stubbed_put_request).to have_been_requested
  end

  def and_the_vaccination_record_is_deleted_from_the_nhs
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    expect(@stubbed_delete_request).to have_been_requested
  end
end
