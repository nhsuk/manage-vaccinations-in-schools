# frozen_string_literal: true

describe "Delete vaccination record" do
  scenario "User doesn't delete the record" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_a_patient_that_is_vaccinated
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_dont_delete_the_vaccination_record
    then_i_see_the_patient
    and_they_are_already_vaccinated
  end

  scenario "User deletes a record and checks activity log" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_a_patient_that_is_vaccinated
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message
    and_they_can_be_vaccinated

    when_i_click_on_the_log
    then_i_see_the_delete_vaccination
  end

  scenario "User deletes a record before confirmation is sent" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_a_patient_that_is_vaccinated
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message
    and_they_can_be_vaccinated

    when_i_click_on_the_log
    then_i_see_the_delete_vaccination
    and_the_parent_doesnt_receives_an_email
  end

  scenario "User deletes a record after confirmation is sent" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_a_confirmation_email_has_been_sent

    when_i_go_to_a_patient_that_is_vaccinated
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message
    and_they_can_be_vaccinated

    when_i_click_on_the_log
    then_i_see_the_delete_vaccination
    and_the_parent_receives_an_email
  end

  scenario "User tries to delete a record for a closed session date" do
    given_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists
    and_the_session_has_closed

    when_i_go_to_a_patient_that_is_vaccinated
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
        programme: @programme
      )

    @patient =
      create(
        :patient,
        :consent_given_triage_needed,
        :triage_ready_to_vaccinate,
        given_name: "John",
        family_name: "Smith",
        programme: @programme,
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
        patient_session: @patient_session,
        batch:
      )
  end

  def and_a_confirmation_email_has_been_sent
    @vaccination_record.update(confirmation_sent_at: Time.current)
  end

  def and_the_session_has_closed
    @session.close!
  end

  def when_i_go_to_a_patient_that_is_vaccinated
    sign_in @organisation.users.first
    visit session_vaccinations_path(@session)
    click_link "Vaccinated"
    click_link @patient.full_name
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

  def and_they_can_be_vaccinated
    expect(page).to have_content("Safe to vaccinate")
    expect(page).not_to have_content("Vaccinated")
  end

  def when_i_click_on_the_log
    click_on "Activity log"
  end

  def then_i_see_the_delete_vaccination
    expect(page).to have_content("Vaccinated with Gardasil 9")
    expect(page).to have_content("HPV vaccination record deleted")
  end

  def and_the_parent_receives_an_email
    expect_email_to(@patient.parents.first.email, :vaccination_deleted)
  end

  def and_the_parent_doesnt_receives_an_email
    expect(sent_emails).to be_empty
  end

  def then_i_cant_click_on_delete_vaccination_record
    expect(page).not_to have_content("Delete vaccination record")
  end
end
