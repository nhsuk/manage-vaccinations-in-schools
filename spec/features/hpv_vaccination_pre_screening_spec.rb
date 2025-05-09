# frozen_string_literal: true

describe "HPV vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Vaccination not allowed after pre-screening" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_has_already_received_the_vaccination
    and_i_choose_that_the_patient_is_ready_to_vaccinate
    then_i_see_an_error_message
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv_all_vaccines)]
    organisation = create(:organisation, :with_one_nurse, programmes:)
    location = create(:school)

    Vaccine
      .where(programme: programmes)
      .discontinued
      .each { |vaccine| create(:batch, organisation:, vaccine:) }

    @session = create(:session, organisation:, programmes:, location:)
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )

    sign_in organisation.users.first
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_has_already_received_the_vaccination
    check "know what the vaccination is for, and are happy to have it"
    check "are feeling well"
    check "have no allergies which would prevent vaccination"
  end

  def and_i_choose_that_the_patient_is_ready_to_vaccinate
    choose "Yes"
    choose "Left arm (upper position)"
    click_button "Continue"
  end

  def then_i_see_an_error_message
    expect(page).to have_content(
      "Confirm that they have not already had the vaccination"
    )
  end
end
