# frozen_string_literal: true

describe "Delete vaccination record" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "User deletes a vaccination record" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_administered_vaccination_record_exists

    when_i_go_to_a_patient_that_is_vaccinated
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_dont_delete_the_vaccination_record
    then_i_see_the_patient
    and_they_are_already_vaccinated
    and_i_click_on_delete_vaccination_record
    then_i_see_the_delete_vaccination_page

    when_i_delete_the_vaccination_record
    then_i_see_the_patient
    and_i_see_a_successful_message
    and_they_can_be_vaccinated
  end

  def given_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse)
    sign_in @organisation.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv, organisations: [@organisation])

    @session =
      create(:session, organisation: @organisation, programme: @programme)

    @patient =
      create(
        :patient,
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

    create(
      :vaccination_record,
      programme: @programme,
      patient_session: @patient_session,
      batch:
    )
  end

  def when_i_go_to_a_patient_that_is_vaccinated
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
end
