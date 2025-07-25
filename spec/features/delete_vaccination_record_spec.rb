# frozen_string_literal: true

describe "Delete vaccination record" do
  scenario "User doesn't delete the record" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_sign_in_as_a_superuser
    and_i_go_to_a_patient_that_is_vaccinated_in_the_session
    and_i_click_on_the_vaccination_record
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_dont_delete_the_vaccination_record
    then_i_see_the_patient
    and_they_are_already_vaccinated
  end

  scenario "User deletes a record and checks activity log" do
    given_an_hpv_programme_is_underway
    and_enqueue_sync_vaccination_records_to_nhs_feature_is_enabled
    and_an_administered_vaccination_record_exists

    when_i_sign_in_as_a_superuser
    and_i_go_to_a_patient_that_is_vaccinated_in_the_session
    and_i_click_on_the_vaccination_record
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message
    and_the_vaccination_record_is_deleted_from_nhs

    when_i_click_on_the_session
    then_i_see_the_patient_can_be_vaccinated

    when_i_click_on_the_log
    then_i_see_the_delete_vaccination
  end

  scenario "User deletes a record before confirmation is sent" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_sign_in_as_a_superuser
    and_i_go_to_a_patient_that_is_vaccinated_in_the_session
    and_i_click_on_the_vaccination_record
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message

    when_i_click_on_the_session
    then_i_see_the_patient_can_be_vaccinated

    when_i_click_on_the_log
    then_i_see_the_delete_vaccination
    and_the_parent_doesnt_receives_an_email
  end

  scenario "User deletes a record after confirmation is sent" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_a_confirmation_email_has_been_sent

    when_i_sign_in_as_a_superuser
    and_i_go_to_a_patient_that_is_vaccinated_in_the_session
    and_i_click_on_the_vaccination_record
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message

    when_i_click_on_the_session
    then_i_see_the_patient_can_be_vaccinated

    when_i_click_on_the_log
    then_i_see_the_delete_vaccination
    and_the_parent_receives_an_email
  end

  scenario "User deletes a record from children page" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_sign_in_as_a_superuser
    and_i_go_to_a_patient_that_is_vaccinated_via_all_children
    and_i_click_on_the_vaccination_record
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message
    and_they_have_no_vaccinations
  end

  scenario "User can't delete a record without superuser access" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_sign_in
    and_i_go_to_a_patient_that_is_vaccinated_in_the_session
    and_i_click_on_the_vaccination_record
    then_i_cant_click_on_delete_vaccination_record
  end

  def given_an_hpv_programme_is_underway
    @organisation = create(:organisation, :with_one_nurse)
    @programme = create(:programme, :hpv, organisations: [@organisation])

    @session =
      create(
        :session,
        date: Date.yesterday,
        organisation: @organisation,
        programmes: [@programme]
      )

    @patient =
      create(
        :patient,
        :consent_given_triage_needed,
        :triage_ready_to_vaccinate,
        given_name: "John",
        family_name: "Smith",
        year_group: 8,
        programmes: [@programme],
        organisation: @organisation
      )

    @patient_session =
      create(:patient_session, patient: @patient, session: @session)
  end

  def and_an_administered_vaccination_record_exists
    vaccine = @programme.vaccines.first

    batch = create(:batch, organisation: @organisation, vaccine:)

    @vaccination_record =
      create(
        :vaccination_record,
        programme: @programme,
        patient: @patient,
        session: @session,
        batch:
      )

    create(
      :patient_session_session_status,
      :vaccinated,
      patient_session: @patient_session,
      programme: @programme
    )

    if Flipper.enabled?(:immunisations_fhir_api_integration)
      perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    end
  end

  def and_a_confirmation_email_has_been_sent
    @vaccination_record.update(confirmation_sent_at: Time.current)
  end

  def and_enqueue_sync_vaccination_records_to_nhs_feature_is_enabled
    Flipper.enable(:enqueue_sync_vaccination_records_to_nhs)
    Flipper.enable(:immunisations_fhir_api_integration)

    uuid = Random.uuid
    @stubbed_post_request = stub_immunisations_api_post(uuid:)
    @stubbed_put_request = stub_immunisations_api_put(uuid:)
    @stubbed_delete_request = stub_immunisations_api_delete(uuid:)
  end

  def when_i_sign_in
    sign_in @organisation.users.first
  end

  def when_i_sign_in_as_a_superuser
    sign_in @organisation.users.first, superuser: true
  end

  def and_i_go_to_a_patient_that_is_vaccinated_in_the_session
    visit session_outcome_path(@session)
    choose "Vaccinated"
    click_on "Update results"
    click_on @patient.full_name
  end

  def and_i_click_on_the_vaccination_record
    click_on Date.current.to_fs(:long)
  end

  def and_i_go_to_a_patient_that_is_vaccinated_via_all_children
    visit patients_path
    click_on @patient.full_name
  end

  def and_i_click_on_delete_vaccination_record
    click_on "Delete vaccination record"
  end

  def then_i_see_the_delete_vaccination_page
    expect(page).to have_content(
      "Are you sure you want to delete this vaccination record?"
    )
  end

  def when_i_dont_delete_the_vaccination_record
    click_on "No, return to patient"
  end

  def then_i_see_the_patient
    expect(page).to have_content(@patient.full_name)
  end

  def and_they_are_already_vaccinated
    expect(page).to have_content("Vaccinated")
  end

  def when_i_delete_the_vaccination_record
    click_on "Yes, delete this vaccination record"
  end

  def and_i_see_a_successful_message
    expect(page).to have_content("Vaccination record deleted")
  end

  def when_i_click_on_the_session
    click_on @session.location.name
  end

  def then_i_see_the_patient_can_be_vaccinated
    expect(page).to have_content("Safe to vaccinate")
    expect(page).not_to have_content("Vaccinated")
  end

  def and_they_have_no_vaccinations
    expect(page).to have_content("No vaccinations")
  end

  def when_i_click_on_the_log
    click_on "Session activity and notes"
  end

  def then_i_see_the_delete_vaccination
    expect(page).to have_content("Vaccinated with Gardasil 9")
    expect(page).to have_content("Vaccination record deleted")
  end

  def and_the_parent_receives_an_email
    expect_email_to(@patient.parents.first.email, :vaccination_deleted)
  end

  def and_the_parent_doesnt_receives_an_email
    expect(email_deliveries).to be_empty
  end

  def then_i_cant_click_on_delete_vaccination_record
    expect(page).not_to have_content("Delete vaccination record")
  end

  def and_the_vaccination_record_is_deleted_from_nhs
    perform_enqueued_jobs(only: SyncVaccinationRecordToNHSJob)
    expect(@stubbed_delete_request).to have_been_requested
  end
end
