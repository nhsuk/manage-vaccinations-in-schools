# frozen_string_literal: true

describe "HPV Vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Administered at a clinic" do
    given_i_am_signed_in
    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_has_been_vaccinated
    and_i_select_the_batch
    and_i_select_a_location
    then_i_see_the_confirmation_page

    when_i_confirm_the_details
    then_i_see_the_record_vaccinations_page
    and_a_success_message

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_vaccinated
    and_an_email_is_sent_to_the_parent_confirming_the_vaccination
    and_a_text_is_sent_to_the_parent_confirming_the_vaccination
  end

  def given_i_am_signed_in
    programme = create(:programme, :hpv_all_vaccines)
    team = create(:team, :with_one_nurse, programmes: [programme])
    location = create(:location, :generic_clinic, team:)

    @community_clinic = create(:location, :community_clinic, team:)

    programme.vaccines.discontinued.each do |vaccine|
      create(:batch, team:, vaccine:)
    end

    active_vaccine = programme.vaccines.active.first
    @active_batch = create(:batch, team:, vaccine: active_vaccine)

    @session = create(:session, team:, programme:, location:)
    @patient =
      create(:patient, :consent_given_triage_not_needed, session: @session)

    sign_in team.users.first
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

  def and_i_select_the_batch
    choose @active_batch.name
    click_button "Continue"
  end

  def and_i_select_a_location
    choose @community_clinic.name
    click_button "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("Child#{@patient.full_name}")
    expect(page).to have_content("Batch#{@active_batch.name}")
    expect(page).to have_content("MethodIntramuscular")
    expect(page).to have_content("SiteLeft arm")
    expect(page).to have_content("OutcomeVaccinated")
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

  def and_an_email_is_sent_to_the_parent_confirming_the_vaccination
    expect_email_to(
      @patient.consents.last.parent.email,
      :confirmation_the_hpv_vaccination_has_taken_place
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_vaccination
    expect_text_to(
      @patient.consents.last.parent.phone,
      :vaccination_has_taken_place
    )
  end
end
