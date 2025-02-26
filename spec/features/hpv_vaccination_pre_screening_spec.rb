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
    visit session_triage_path(@session)
    click_link "No triage needed"
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_has_already_received_the_vaccination
    within(
      "fieldset",
      text:
        "Does the child know what the vaccination is for, and are they happy to have it?"
    ) { choose "Yes" }

    within(
      "fieldset",
      text:
        "Has the child confirmed they have not already had this vaccination?"
    ) { choose "No" }

    within("fieldset", text: "Is the child is feeling well?") { choose "Yes" }

    within(
      "fieldset",
      text:
        "Has the child confirmed they have no allergies which would prevent vaccination?"
    ) { choose "Yes" }
  end

  def and_i_choose_that_the_patient_is_ready_to_vaccinate
    find_all(".nhsuk-fieldset")[4].choose "Yes"
    choose "Left arm (upper position)"
    click_button "Continue"
  end

  def then_i_see_an_error_message
    expect(page).to have_content("Patient should not be vaccinated")
  end
end
