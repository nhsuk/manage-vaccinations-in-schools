# frozen_string_literal: true

describe "Manage children" do
  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  before { given_my_team_exists }

  scenario "Viewing children" do
    given_patients_exist
    and_the_patient_is_vaccinated

    when_i_click_on_children
    then_i_see_no_children_by_default

    when_i_filter_for_children
    then_i_see_the_children

    when_i_click_on_a_child
    then_i_see_the_child

    when_i_click_on_activity_log
    then_i_see_the_activity_log
  end

  scenario "Viewing children paginated" do
    given_many_patients_exist

    when_i_click_on_children
    and_i_filter_for_children
    then_i_see_the_children
    and_i_see_the_pages

    when_i_visit_an_overflow_page
    then_i_see_the_last_page
  end

  scenario "Viewing children who have aged out" do
    given_patients_exist
    and_todays_date_is_in_the_far_future

    when_i_click_on_children
    and_i_filter_for_children
    then_i_see_no_children

    when_i_click_on_view_aged_out_children
    then_i_see_the_children
  end

  scenario "Adding an NHS number" do
    given_patients_exist
    and_sync_vaccination_records_to_nhs_feature_is_enabled
    and_the_patient_is_vaccinated

    when_i_click_on_children
    and_i_filter_for_children
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
    and_i_filter_for_children
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
    and_the_important_notice_is_dismissed
  end

  scenario "Inviting to community clinic" do
    given_patients_exist

    when_i_click_on_children
    and_i_filter_for_children
    and_i_click_on_a_child
    then_i_see_the_child
    and_i_dont_see_a_community_clinic_session

    when_i_click_on_invite_to_clinic
    then_i_see_a_success_banner
    and_i_see_a_community_clinic_session
    and_i_dont_see_an_invite_to_clinic_session
  end

  scenario "Removing an NHS number" do
    given_patients_exist
    and_sync_vaccination_records_to_nhs_feature_is_enabled
    and_the_patient_is_vaccinated
    and_the_vaccination_has_been_synced_to_nhs

    when_i_click_on_children
    and_i_filter_for_children
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

    when_i_click_on_dismiss
    and_i_choose_to_dismiss
    then_i_see_no_notices
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

    when_i_click_on_dismiss
    and_i_choose_not_to_dismiss
    then_i_see_the_notice_of_sensitive

    when_i_click_on_dismiss
    and_i_choose_to_dismiss
    then_i_see_no_notices
    and_i_see_a_success_banner
  end

  def given_my_team_exists
    @hpv = CachedProgramme.hpv
    @flu = CachedProgramme.flu
    @team =
      create(
        :team,
        :with_generic_clinic,
        :with_one_nurse,
        programmes: [@hpv, @flu]
      )

    TeamSessionsFactory.call(@team, academic_year: AcademicYear.current)
  end

  def given_patients_exist
    school = create(:school, team: @team)

    @session =
      create(:session, location: school, team: @team, programmes: [@hpv])

    @patient =
      create(
        :patient,
        session: @session,
        given_name: "John",
        family_name: "Smith",
        school:
      )
    create_list(:patient, 9, session: @session)

    another_session = create(:session, team: @team, programmes: [@hpv])

    @existing_patient =
      create(
        :patient,
        session: another_session,
        given_name: "Jane",
        family_name: "Doe"
      )

    StatusUpdater.call
  end

  def given_many_patients_exist
    @session = create(:session, team: @team, programmes: [@hpv])

    create_list(:patient, 100, session: @session)

    StatusUpdater.call
  end

  def given_an_invalidated_patient_exists
    session = create(:session, team: @team, programmes: [@hpv])

    @patient =
      create(
        :patient,
        :invalidated,
        session:,
        given_name: "John",
        family_name: "Smith"
      )

    create(:patient, session:, nhs_number: nil)

    StatusUpdater.call
  end

  def and_the_patient_is_vaccinated
    create(
      :vaccination_record,
      patient: @patient,
      programme: @hpv,
      session: @session
    )
  end

  def and_sync_vaccination_records_to_nhs_feature_is_enabled
    Flipper.enable(:imms_api_sync_job)
    Flipper.enable(:imms_api_integration)

    immunisation_uuid = Random.uuid
    @stubbed_post_request = stub_immunisations_api_post(uuid: immunisation_uuid)
    @stubbed_put_request = stub_immunisations_api_put(uuid: immunisation_uuid)
    @stubbed_delete_request =
      stub_immunisations_api_delete(uuid: immunisation_uuid)
  end

  def and_the_vaccination_has_been_synced_to_nhs
    Sidekiq::Job.drain_all
  end

  def and_todays_date_is_in_the_far_future
    travel 13.years
  end

  def when_a_deceased_patient_exists
    session = create(:session, team: @team, programmes: [@hpv])

    @deceased_patient = create(:patient, :deceased, session:)
  end

  def when_an_invalidated_patient_exists
    session = create(:session, team: @team, programmes: [@hpv])

    @invalidated_patient = create(:patient, :invalidated, session:)
  end

  def when_a_restricted_patient_exists
    session = create(:session, team: @team, programmes: [@hpv])

    @restricted_patient = create(:patient, :restricted, session:)
  end

  def when_i_click_on_children
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Children", match: :first
  end

  def then_i_see_no_children_by_default
    expect(page).to have_content(
      "Search for a child or use filters to see children matching your selection."
    )
  end

  def when_i_filter_for_children
    check "No response"
    click_on "Update results"
  end

  alias_method :and_i_filter_for_children, :when_i_filter_for_children

  def then_i_see_the_children
    expect(page).to have_content(/\d+ children/)
  end

  def then_i_see_no_children
    expect(page).to have_content("No children")
  end

  def and_i_see_the_pages
    expect(page).to have_content("Next page")
    expect(page).to have_content("Showing 1 to 50 of 100 children")
  end

  def when_i_visit_an_overflow_page
    click_on "2"
  end

  def then_i_see_the_last_page
    expect(page).to have_content("Previous page")
    expect(page).to have_content("Showing 51 to 100 of 100 children")
  end

  def when_i_click_on_view_aged_out_children
    find(".nhsuk-details__summary").click
    uncheck "No response"
    check "Children aged out of programmes"
    click_on "Update results"
  end

  def when_i_click_on_a_child
    click_on "SMITH, John"
  end

  alias_method :and_i_click_on_a_child, :when_i_click_on_a_child

  def then_i_see_the_child
    expect(page).to have_title("JS")
    expect(page).to have_content("SMITH, John")
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
    travel 1.minute
    fill_in "What is the child’s NHS number?", with: ""
    click_on "Continue"
  end

  def and_i_enter_an_existing_nhs_number
    fill_in "What is the child’s NHS number?",
            with: @existing_patient.nhs_number
    click_on "Continue"
  end

  def and_i_see_the_nhs_number
    expect(page).to have_content("975 862 3168")
  end

  def and_the_patient_is_no_longer_invalidated
    expect(@patient.reload).not_to be_invalidated
  end

  def and_the_important_notice_is_dismissed
    notice = @patient.important_notices.find_by(type: :invalidated)
    expect(notice.dismissed_at).to be_present
  end

  def and_i_see_the_blank_nhs_number
    expect(page).to have_content("NHS numberNot provided")
  end

  def then_i_see_the_merge_record_page
    expect(page).to have_content("Do you want to merge this record?")
    expect(page).to have_content("DOE, Jane")
  end

  def when_i_click_on_merge_records
    travel 1.minute
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

  def and_i_dont_see_a_community_clinic_session
    expect(page).not_to have_content("Community clinic")
  end

  def when_i_click_on_invite_to_clinic
    click_on "Invite to community clinic"
  end

  def then_i_see_a_success_banner
    expect(page).to have_content("invited to the clinic")
  end

  def and_i_see_a_community_clinic_session
    expect(page).to have_content("Community clinic")
  end

  def and_i_dont_see_an_invite_to_clinic_session
    expect(page).not_to have_button("Invite to community clinic")
  end

  def when_i_go_to_the_dashboard
    sign_in @team.users.first

    visit "/dashboard"
  end

  def when_i_go_to_the_imports_page
    sign_in @team.users.first

    visit "/imports"
  end

  def when_i_go_to_the_imports_page_as_a_superuser
    sign_in @team.users.first, superuser: true

    visit "/imports"
  end

  def when_i_wait_for_the_sync_to_complete
    Sidekiq::Job.drain_all
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

  def when_i_click_on_dismiss
    click_on "Dismiss"
  end

  def and_i_choose_to_dismiss
    click_on "Yes, dismiss this notice"
  end

  def and_i_choose_not_to_dismiss
    click_on "No, return to notices"
  end

  def then_i_see_no_notices
    expect(page).to have_content("There are currently no important notices.")
  end

  def and_i_see_a_success_banner
    expect(page).to have_content("Notice dismissed")
  end

  def then_i_see_the_notice_of_date_of_death
    expect(page).to have_content("Important notices (1)")
    expect(page).to have_content(@deceased_patient.full_name)
    expect(page).to have_content("Record updated with child’s date of death")
  end

  def then_i_see_the_notice_of_invalid
    expect(page).to have_content("Important notices (1)")
    expect(page).to have_content(@invalidated_patient.full_name)
    expect(page).to have_content("Record flagged as invalid")
  end

  def then_i_see_the_notice_of_sensitive
    expect(page).to have_content("Important notices (1)")
    expect(page).to have_content(@restricted_patient.full_name)
    expect(page).to have_content("Record flagged as sensitive")
  end

  def then_the_vaccination_record_is_created_with_the_nhs
    expect(@stubbed_post_request).to have_been_requested
  end

  def and_the_vaccination_record_is_updated_with_the_nhs
    Sidekiq::Job.drain_all
    expect(@stubbed_put_request).to have_been_requested
  end

  def and_the_vaccination_record_is_deleted_from_the_nhs
    Sidekiq::Job.drain_all
    expect(@stubbed_delete_request).to have_been_requested
  end
end
