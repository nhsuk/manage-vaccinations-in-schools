# frozen_string_literal: true

describe "HPV Vaccination" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Administered" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_has_been_vaccinated
    and_i_see_only_not_expired_batches
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_click_change_outcome
    and_i_record_that_the_patient_has_been_vaccinated
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_click_change_batch
    and_i_select_the_batch
    then_i_see_the_confirmation_page

    when_i_confirm_the_details
    then_i_see_the_record_vaccinations_page
    and_a_success_message

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_vaccinated
    and_i_see_the_vaccination_details
    and_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  def given_i_am_signed_in
    programme = create(:programme, :hpv_all_vaccines)
    organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])
    location = create(:location, :school)

    programme.vaccines.discontinued.each do |vaccine|
      create(:batch, organisation:, vaccine:)
    end

    active_vaccine = programme.vaccines.active.first
    @active_batch = create(:batch, organisation:, vaccine: active_vaccine)
    @archived_batch =
      create(:batch, :archived, organisation:, vaccine: active_vaccine)

    # To get around expiration date validation on the model.
    @expired_batch =
      build(:batch, :expired, organisation:, vaccine: active_vaccine)
    @expired_batch.save!(validate: false)

    @session = create(:session, organisation:, programme:, location:)
    @patient =
      create(:patient, :consent_given_triage_not_needed, session: @session)

    sign_in organisation.users.first
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_triage_path(@session)
    click_link "No triage needed"
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_has_been_vaccinated
    choose "Yes, they got the HPV vaccine"
    choose "Left arm"
    click_button "Continue"
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

  def when_i_click_change_batch
    click_on "Change batch"
  end

  def when_i_confirm_the_details
    click_button "Confirm"
  end

  def then_i_see_the_record_vaccinations_page
    expect(page).to have_content("Record vaccinations")
  end

  def and_a_success_message
    expect(page).to have_content(
      "Vaccination recorded for #{@patient.full_name}"
    )
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name
  end

  def then_i_see_that_the_status_is_vaccinated
    expect(page).to have_content("Vaccinated")
  end

  def and_i_see_the_vaccination_details
    expect(page).to have_content("Vaccination details")
  end

  def and_an_email_is_sent_to_the_parent_confirming_the_vaccination
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_confirmation_administered
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    expect_text_to(
      @patient.consents.last.parent.phone,
      :vaccination_confirmation_administered
    )
  end
end
