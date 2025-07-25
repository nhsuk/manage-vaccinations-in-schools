# frozen_string_literal: true

describe "Td/IPV vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Administered" do
    given_i_am_signed_in
    and_enqueue_sync_vaccination_records_to_nhs_feature_is_enabled

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_has_been_vaccinated
    and_i_see_only_not_expired_batches
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_click_change_outcome
    and_i_choose_vaccinated
    and_i_select_the_delivery
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_click_change_batch
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_click_change_delivery_site
    and_i_select_the_delivery
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_click_change_date
    and_i_select_the_date
    and_i_choose_vaccinated
    and_i_select_the_delivery
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_confirm_the_details
    then_i_see_a_success_message
    and_i_no_longer_see_the_patient_in_the_record_tab
    and_the_vaccination_record_is_not_synced_to_nhs

    when_i_go_back
    and_i_save_changes
    then_i_see_that_the_status_is_vaccinated
    and_i_see_the_vaccination_details

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  def given_i_am_signed_in
    programme = create(:programme, :td_ipv)
    organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])
    location = create(:school, organisation:)

    programme.vaccines.discontinued.each do |vaccine|
      create(:batch, organisation:, vaccine:)
    end

    @active_vaccine = programme.vaccines.active.first
    @active_batch =
      create(:batch, :not_expired, organisation:, vaccine: @active_vaccine)
    @archived_batch =
      create(:batch, :archived, organisation:, vaccine: @active_vaccine)

    # To get around expiration date validation on the model.
    @expired_batch =
      build(:batch, :expired, organisation:, vaccine: @active_vaccine)
    @expired_batch.save!(validate: false)

    @session =
      create(:session, organisation:, programmes: [programme], location:)
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )

    sign_in organisation.users.first
  end

  def and_enqueue_sync_vaccination_records_to_nhs_feature_is_enabled
    Flipper.enable(:enqueue_sync_vaccination_records_to_nhs)
    Flipper.enable(:immunisations_fhir_api_integration)

    @stubbed_post_request = stub_immunisations_api_post
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_has_been_vaccinated
    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end
  end

  def and_i_see_only_not_expired_batches
    expect(page).not_to have_content(@expired_batch.name)
    expect(page).not_to have_content(@archived_batch.name)
    expect(page).to have_content(@active_batch.name)
  end

  def and_i_select_the_batch
    choose @active_batch.name
    click_button "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("Child#{@patient.full_name}")
    expect(page).to have_content("Batch ID#{@active_batch.name}")
    expect(page).to have_content("MethodIntramuscular")
    expect(page).to have_content("SiteLeft arm")
    expect(page).to have_content("OutcomeVaccinated")
  end

  def when_i_click_change_outcome
    click_on "Change outcome"
  end

  def and_i_choose_vaccinated
    choose "Vaccinated"
    click_on "Continue"
  end

  def when_i_click_change_batch
    click_on "Change batch"
  end

  def when_i_click_change_delivery_site
    click_on "Change site"
  end

  def and_i_select_the_delivery
    choose "Intramuscular"
    choose "Left arm (upper position)"
    click_on "Continue"
  end

  def when_i_click_change_date
    click_on "Change date"
  end

  def and_i_select_the_date
    click_on "Continue"
  end

  def when_i_confirm_the_details
    click_button "Confirm"
  end

  def then_i_see_a_success_message
    expect(page).to have_content("Vaccination outcome recorded for Td/IPV")
  end

  def and_i_no_longer_see_the_patient_in_the_record_tab
    click_on "Record vaccinations"
    expect(page).to have_content("No children matching search criteria found")
  end

  def when_i_go_back
    visit draft_vaccination_record_path("confirm")
  end

  def and_i_save_changes
    click_button "Save changes"
  end

  def then_i_see_that_the_status_is_vaccinated
    expect(page).to have_content("Vaccinated")
  end

  def and_i_see_the_vaccination_details
    expect(page).to have_content("Vaccinations")
    click_on Date.current.to_fs(:long)

    expect(page).to have_content("Vaccination details")
    expect(page).to have_content("Dose numberUnknown")
  end

  def when_vaccination_confirmations_are_sent
    SendVaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_vaccination
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_administered_td_ipv
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_administered
    )
  end

  def and_the_vaccination_record_is_not_synced_to_nhs
    perform_enqueued_jobs
    expect(@stubbed_post_request).not_to have_been_requested
  end
end
