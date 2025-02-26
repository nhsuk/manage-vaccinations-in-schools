# frozen_string_literal: true

describe "HPV vaccination" do
  scenario "Already had" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_wasnt_vaccinated
    and_i_select_the_reason_why
    then_i_see_the_confirmation_page

    when_i_click_change_outcome
    and_i_select_the_reason_why
    then_i_see_the_confirmation_page

    when_i_confirm_the_details
    then_i_see_the_record_vaccinations_page
    and_a_success_message

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_could_not_vaccinate

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_saying_the_vaccination_didnt_happen
    and_a_text_is_sent_saying_the_vaccination_didnt_happen
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    organisation = create(:organisation, :with_one_nurse, programmes:)
    location = create(:school)
    @batch =
      create(:batch, organisation:, vaccine: programmes.first.vaccines.first)
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

  def and_i_record_that_the_patient_wasnt_vaccinated
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

    find_all(".nhsuk-fieldset")[4].choose "No"
    click_button "Continue"
  end

  def and_i_select_the_reason_why
    choose "They have already had the vaccine"
    click_button "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("Vaccination was not given")
    expect(page).to have_content("Child#{@patient.full_name}")
    expect(page).to have_content("OutcomeAlready had")
  end

  def when_i_click_change_outcome
    click_on "Change outcome"
  end

  def when_i_confirm_the_details
    click_button "Confirm"
  end

  def then_i_see_the_record_vaccinations_page
    expect(page).to have_content("Record vaccinations")
  end

  def and_a_success_message
    expect(page).to have_content("Record updated for #{@patient.full_name}")
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name
  end

  def then_i_see_that_the_status_is_could_not_vaccinate
    expect(page).to have_content("Could not vaccinate")
    expect(page).to have_content(
      "Reason#{@patient.full_name} has already had the vaccine"
    )
  end

  def when_vaccination_confirmations_are_sent
    VaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_saying_the_vaccination_didnt_happen
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_confirmation_not_administered
    )
  end

  def and_a_text_is_sent_saying_the_vaccination_didnt_happen
    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_confirmation_not_administered
    )
  end
end
