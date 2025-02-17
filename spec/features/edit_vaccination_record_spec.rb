# frozen_string_literal: true

describe "Edit vaccination record" do
  scenario "User edits a new vaccination record" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
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

    when_i_click_change_vaccine
    and_i_choose_a_vaccine
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_batch
    and_i_choose_a_batch
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_batch

    when_i_click_change_notes
    and_i_enter_some_notes
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_the_parent_doesnt_receive_an_email
  end

  scenario "User edits a vaccination record that already received confirmation" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_date
    then_i_should_see_the_date_time_form

    when_i_fill_in_a_valid_date_and_time
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_date_time

    when_i_click_change_vaccine
    and_i_choose_a_vaccine
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_batch
    and_i_choose_a_batch
    then_i_see_the_edit_vaccination_record_page
    and_i_should_see_the_updated_batch

    when_i_click_on_save_changes
    then_the_parent_receives_an_administered_email
  end

  scenario "User edits a vaccination record, not enough to trigger an email" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
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
    and_an_hpv_programme_is_underway
    and_a_not_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
    then_i_should_see_the_vaccination_record

    when_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_outcome
    then_i_should_see_the_change_outcome_form
    and_i_choose_vaccinated
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_add_vaccine
    and_i_choose_a_vaccine
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
  end

  scenario "Edit outcome to not vaccinated" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_the_vaccination_confirmation_was_already_sent

    when_i_go_to_the_vaccination_records_page
    then_i_should_see_the_vaccination_records

    when_i_click_on_the_vaccination_record
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
  end

  scenario "With an archived batch" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_the_original_batch_has_been_archived

    when_i_go_to_the_vaccination_records_page
    and_i_click_on_the_vaccination_record
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
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_the_original_batch_has_expired

    when_i_go_to_the_vaccination_records_page
    and_i_click_on_the_vaccination_record
    and_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_change_batch
    and_i_choose_the_original_batch
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
  end

  scenario "Cannot as an admin" do
    given_i_am_signed_in_as_an_admin
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_records_page
    and_i_click_on_the_vaccination_record
    then_i_should_not_be_able_to_edit_the_vaccination_record
  end

  scenario "Navigating back" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_the_vaccination_records_page
    and_i_click_on_the_vaccination_record
    and_i_click_on_edit_vaccination_record
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record

    when_i_go_back_to_the_confirm_page
    then_i_see_the_edit_vaccination_record_page

    when_i_click_on_save_changes
    then_i_should_see_the_vaccination_record
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse, ods_code: "R1L")
    sign_in @organisation.users.first
  end

  def given_i_am_signed_in_as_an_admin
    @organisation = create(:organisation, :with_one_admin, ods_code: "R1L")
    sign_in @organisation.users.first, role: :admin_staff
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv, organisations: [@organisation])

    @vaccine = @programme.vaccines.first

    @original_batch =
      create(:batch, organisation: @organisation, vaccine: @vaccine)
    @replacement_batch =
      create(:batch, organisation: @organisation, vaccine: @vaccine)

    location = create(:school)

    @session =
      create(
        :session,
        :completed,
        organisation: @organisation,
        programme: @programme,
        location:
      )

    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        given_name: "John",
        family_name: "Smith",
        organisation: @organisation,
        programme: @programme
      )

    @patient_session =
      create(:patient_session, patient: @patient, session: @session)
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

  def when_i_go_to_the_vaccination_records_page
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
  end

  def then_i_should_see_the_vaccination_records
    expect(page).to have_content("1 vaccination record")
    expect(page).to have_content("SMITH, John")
  end

  def when_i_click_on_the_vaccination_record
    click_on "SMITH, John"
  end

  alias_method :and_i_click_on_the_vaccination_record,
               :when_i_click_on_the_vaccination_record

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
    fill_in "Year", with: "2023"
    fill_in "Month", with: "9"
    fill_in "Day", with: "1"

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
    expect(page).to have_content("Date1 September 2023")
    expect(page).to have_content("Time12:00pm")
  end

  def when_i_click_change_vaccine
    click_on "Change vaccine"
  end

  def and_i_choose_a_vaccine
    choose "Gardasil 9 (HPV)"
    click_on "Continue"
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
    click_on "Save changes"
  end

  def then_the_parent_doesnt_receive_an_email
    expect(email_deliveries).to be_empty
  end

  alias_method :and_the_parent_doesnt_receive_an_email,
               :then_the_parent_doesnt_receive_an_email

  def and_the_parent_receives_a_not_administered_email
    expect_email_to(
      @patient.parents.first.email,
      :vaccination_confirmation_not_administered
    )
  end

  def then_the_parent_receives_an_administered_email
    expect_email_to(
      @patient.parents.first.email,
      :vaccination_confirmation_administered
    )
  end

  alias_method :and_the_parent_receives_an_administered_email,
               :then_the_parent_receives_an_administered_email

  def then_i_should_not_be_able_to_edit_the_vaccination_record
    expect(page).not_to have_content("Edit vaccination record")
  end

  def when_i_go_back_to_the_confirm_page
    visit draft_vaccination_record_path(id: "confirm")
  end
end
