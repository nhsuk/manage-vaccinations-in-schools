# frozen_string_literal: true

describe "Pre-screening" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "must be confirmed before vaccinating HPV" do
    given_a_session_exists(:hpv)

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    then_i_see_the_pre_screening_questions
    and_i_dont_see_the_medication_question
    and_i_dont_see_the_pregnancy_question
    and_i_record_vaccination_without_pre_screening_checks
    then_i_see_an_error_message
  end

  scenario "must be confirmed before vaccinating MenACWY" do
    given_a_session_exists(:menacwy)

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    then_i_see_the_pre_screening_questions
    and_i_see_the_medication_question
    and_i_dont_see_the_pregnancy_question
    and_i_record_vaccination_without_pre_screening_checks
    then_i_see_an_error_message
  end

  scenario "must be confirmed before vaccinating Td/IPV" do
    given_a_session_exists(:td_ipv)

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    then_i_see_the_pre_screening_questions
    and_i_see_the_medication_question
    and_i_see_the_pregnancy_question
    and_i_record_vaccination_without_pre_screening_checks
    then_i_see_an_error_message
  end

  def given_a_session_exists(programme_type)
    programme = create(:programme, programme_type)
    organisation = create(:organisation, programmes: [programme])

    @nurse = create(:nurse, organisations: [organisation])

    @session =
      create(
        :session,
        organisation:,
        programmes: [programme],
        location: create(:school, organisation:)
      )

    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session,
        year_group: programme.year_groups.first
      )
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    sign_in @nurse
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def then_i_see_the_pre_screening_questions
    expect(page).to have_content(
      "know what the vaccination is for, and are happy to have it"
    )
    expect(page).to have_content("have not already had this vaccination")
    expect(page).to have_content("are not acutely unwell")
    expect(page).to have_content(
      "have no allergies which would prevent vaccination"
    )
  end

  def and_i_see_the_medication_question
    expect(page).to have_content(
      "are not taking any medication which prevents vaccination"
    )
  end

  def and_i_dont_see_the_medication_question
    expect(page).not_to have_content(
      "are not taking any medication which prevents vaccination"
    )
  end

  def and_i_see_the_pregnancy_question
    expect(page).to have_content("are not pregnant")
  end

  def and_i_dont_see_the_pregnancy_question
    expect(page).not_to have_content("are not pregnancy")
  end

  def and_i_record_vaccination_without_pre_screening_checks
    within all("section")[0] do
      choose "Yes"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end
  end

  def then_i_see_an_error_message
    expect(page).to have_content(
      "Select if the child has confirmed all pre-screening statements are true"
    )
  end
end
