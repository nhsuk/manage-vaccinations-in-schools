# frozen_string_literal: true

describe "Edit vaccination record" do
  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  before { given_an_hpv_programme_is_underway }

  scenario "User edits a new vaccination record" do
    given_i_am_signed_in
    and_an_administered_vaccination_record_exists
    and_imms_api_sync_job_feature_is_enabled

    when_i_go_to_the_vaccination_record_for_the_patient
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_back
    then_i_should_see_the_vaccination_record
    and_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_date
    then_i_should_see_the_date_time_form

    when_i_fill_in_an_invalid_date
    then_i_see_the_date_time_form_with_errors

    when_i_fill_in_an_invalid_time
    then_i_see_the_date_time_form_with_errors

    when_i_fill_in_a_valid_date_and_time
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_date_time

    when_i_click_on_change_batch
    and_i_choose_a_batch
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_batch

    when_i_click_change_notes
    and_i_enter_some_notes
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_the_parent_doesnt_receive_an_email
    and_the_vaccination_record_is_synced_to_nhs
  end

  scenario "User edits a vaccination record that already received confirmation" do
    given_i_am_signed_in
    and_an_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_record_for_the_patient
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_date
    then_i_should_see_the_date_time_form

    when_i_fill_in_a_valid_date_and_time
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_date_time

    when_i_click_on_change_batch
    and_i_choose_a_batch
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_batch

    when_i_click_on_save_changes
    then_the_parent_receives_an_administered_email
  end

  scenario "User edits a vaccination record, not enough to trigger an email" do
    given_i_am_signed_in
    and_an_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_record_for_the_patient
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_delivery_method
    and_i_choose_a_delivery_method_and_site
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_the_parent_doesnt_receive_an_email
  end

  scenario "Edit outcome to vaccinated" do
    given_i_am_signed_in
    and_imms_api_sync_job_feature_is_enabled
    and_a_not_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_record_for_the_patient
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_outcome
    then_i_should_see_the_change_outcome_form
    and_i_choose_vaccinated
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_add_batch
    and_i_choose_a_batch
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_batch

    when_i_click_on_add_delivery_method
    and_i_choose_a_delivery_method_and_site
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
    and_the_parent_receives_an_administered_email
    and_the_vaccination_record_is_synced_to_nhs
  end

  scenario "Edit outcome to not vaccinated" do
    given_i_am_signed_in
    and_imms_api_sync_job_feature_is_enabled
    and_an_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_record_for_the_patient
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_outcome
    then_i_should_see_the_change_outcome_form
    and_i_choose_unwell
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
    and_the_parent_receives_a_not_administered_email
    and_the_vaccination_record_is_deleted_from_nhs
  end

  scenario "With an archived batch" do
    given_i_am_signed_in
    and_an_administered_vaccination_record_exists
    and_the_original_batch_has_been_archived

    when_i_go_to_the_vaccination_record_for_the_patient
    and_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_batch
    and_i_choose_the_original_batch
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
  end

  scenario "With an expired batch" do
    given_i_am_signed_in
    and_an_administered_vaccination_record_exists
    and_the_original_batch_has_expired

    when_i_go_to_the_vaccination_record_for_the_patient
    and_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_batch
    and_i_choose_the_original_batch
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
  end

  scenario "Cannot as a medical secretary" do
    given_i_am_signed_in_as_an_admin
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_record_for_the_patient
    then_i_should_not_be_able_to_edit_the_vaccination_record
  end

  scenario "Navigating back" do
    given_i_am_signed_in
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_record_for_the_patient
    and_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record

    when_i_go_back_to_the_confirm_page
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)

    @team =
      create(
        :team,
        :with_generic_clinic,
        :with_one_nurse,
        ods_code: "R1L",
        programmes: [@programme]
      )

    @vaccine = @programme.vaccines.first

    @original_batch = create(:batch, team: @team, vaccine: @vaccine)
    @replacement_batch =
      create(:batch, :not_expired, team: @team, vaccine: @vaccine)

    location = create(:school, team: @team)

    @session =
      create(
        :session,
        :completed,
        team: @team,
        programmes: [@programme],
        location:
      )

    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        given_name: "John",
        family_name: "Smith",
        team: @team,
        session: @session
      )
  end

  def given_i_am_signed_in
    sign_in @team.users.first
  end

  def given_i_am_signed_in_as_an_admin
    sign_in @team.users.first, role: :medical_secretary
  end

  def and_an_administered_vaccination_record_exists
    @vaccination_record =
      create(
        :vaccination_record,
        batch: @original_batch,
        patient: @patient,
        session: @session,
        programme: @programme
      )

    if Flipper.enabled?(:imms_api_integration)
      perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    end
  end

  def and_imms_api_sync_job_feature_is_enabled
    Flipper.enable(:imms_api_sync_job)
    Flipper.enable(:imms_api_integration)

    uuid = Random.uuid
    @stubbed_post_request = stub_immunisations_api_post(uuid:)
    @stubbed_put_request = stub_immunisations_api_put(uuid:)
    @stubbed_delete_request = stub_immunisations_api_delete(uuid:)
  end

  def and_an_historical_administered_vaccination_record_exists
    @vaccination_record =
      create(
        :vaccination_record,
        batch: @original_batch,
        patient: @patient,
        session: @session,
        performed_by_family_name: "Joy",
        performed_by_given_name: "Nurse",
        performed_by_user: nil,
        programme: @programme
      )
  end

  def and_a_not_administered_vaccination_record_exists
    @vaccination_record =
      create(
        :vaccination_record,
        :not_administered,
        batch: @original_batch,
        patient: @patient,
        session: @session,
        programme: @programme
      )

    +if Flipper.enabled?(:imms_api_integration) &&
         Flipper.enabled?(:imms_api_sync_job)
      perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    end
  end

  def and_the_vaccination_confirmation_was_already_sent
    @vaccination_record.update!(confirmation_sent_at: Time.current)
  end

  def and_the_original_batch_has_been_archived
    @original_batch.update!(archived_at: Time.current)
  end

  def and_the_original_batch_has_expired
    @original_batch.expiry = 1.day.ago
    @original_batch.save!(validate: false)
  end

  def when_i_go_to_the_vaccination_record_for_the_patient
    visit "/dashboard"

    click_on "Children", match: :first
    click_on @patient.full_name
    click_on Date.current.to_fs(:long)
  end

  def then_i_should_see_the_vaccination_record
    expect(page).to have_content("Full nameSMITH, John")
  end

  def when_i_click_on_edit_vaccination_record
    click_on "Edit vaccination record"
  end

  alias_method :and_i_click_on_edit_vaccination_record,
               :when_i_click_on_edit_vaccination_record

  def then_i_see_the_edit_vaccination_record_page
    expect(page).to have_content("Edit vaccination record")
  end

  def when_i_click_back
    click_on "Back"
  end

  def when_i_click_on_change_date
    click_on "Change date"
  end

  def then_i_should_see_the_date_time_form
    expect(page).to have_content("Date")
    expect(page).to have_content("Time")
  end

  def when_i_fill_in_a_valid_date_and_time
    @valid_date = Date.current - 1.day

    fill_in "Year", with: @valid_date.year.to_s
    fill_in "Month", with: @valid_date.month.to_s
    fill_in "Day", with: @valid_date.day.to_s

    fill_in "Hour", with: "12"
    fill_in "Minute", with: "00"

    click_on "Continue"
  end

  def when_i_fill_in_an_invalid_date
    fill_in "Year", with: "3023"
    fill_in "Month", with: "19"
    fill_in "Day", with: "33"

    fill_in "Hour", with: "23"
    fill_in "Minute", with: "15"

    click_on "Continue"
  end

  def when_i_fill_in_an_invalid_time
    fill_in "Year", with: "2025"
    fill_in "Month", with: "5"
    fill_in "Day", with: "1"

    fill_in "Hour", with: "25"
    fill_in "Minute", with: "61"

    click_on "Continue"
  end

  def then_i_see_the_date_time_form_with_errors
    expect(page).to have_content("There is a problem")
  end

  def and_i_should_see_the_updated_date_time
    formatted_date = @valid_date.strftime("%-d %B %Y")

    expect(page).to have_content("Date#{formatted_date}")
    expect(page).to have_content("Time12:00pm")
  end

  def when_i_click_change_vaccine
    click_on "Change vaccine"
  end

  def when_i_click_on_change_batch
    click_on "Change batch"
  end

  def and_i_choose_the_original_batch
    choose @original_batch.name
    click_on "Continue"
  end

  def and_i_choose_a_batch
    choose @replacement_batch.name
    click_on "Continue"
  end

  def and_i_should_see_the_updated_batch
    expect(page).to have_content("Batch ID#{@replacement_batch.name}")
  end

  def when_i_click_change_notes
    click_on "Add notes"
  end

  def and_i_enter_some_notes
    fill_in "Notes", with: "Some notes."
    click_on "Continue"
  end

  def when_i_click_on_change_outcome
    click_on "Change outcome"
  end

  def then_i_should_see_the_change_outcome_form
    expect(page).to have_content("Vaccination outcome")
  end

  def and_i_choose_vaccinated
    choose "Vaccinated"
    click_on "Continue"
  end

  def and_i_choose_unwell
    choose "They were not well enough"
    click_on "Continue"
  end

  def when_i_click_on_add_vaccine
    # vaccine is already populated for us as there is only one
    click_on "Change vaccine"
  end

  def when_i_click_on_add_batch
    click_on "Add batch"
  end

  def when_i_click_on_add_delivery_method
    click_on "Add method"
  end

  def when_i_click_on_change_delivery_method
    click_on "Change method"
  end

  def and_i_choose_a_delivery_method_and_site
    choose "Intramuscular"
    choose "Left arm (upper position)"
    click_on "Continue"
  end

  def when_i_click_on_save_changes
    travel 1.minute
    click_on "Save changes"
  end

  def then_the_parent_doesnt_receive_an_email
    expect(email_deliveries).to be_empty
  end

  alias_method :and_the_parent_doesnt_receive_an_email,
               :then_the_parent_doesnt_receive_an_email

  def and_the_parent_receives_a_not_administered_email
    expect_email_to(@patient.parents.first.email, :vaccination_not_administered)
  end

  def then_the_parent_receives_an_administered_email
    expect_email_to(@patient.parents.first.email, :vaccination_administered_hpv)
  end

  alias_method :and_the_parent_receives_an_administered_email,
               :then_the_parent_receives_an_administered_email

  def then_i_should_not_be_able_to_edit_the_vaccination_record
    expect(page).not_to have_content("Edit vaccination record")
  end

  def when_i_go_back_to_the_confirm_page
    visit draft_vaccination_record_path(id: "confirm")
  end

  def and_the_vaccination_record_is_synced_to_nhs
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    expect(@stubbed_post_request).to have_been_requested
  end

  def and_the_vaccination_record_is_deleted_from_nhs
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    expect(@stubbed_delete_request).to have_been_requested
  end
end
