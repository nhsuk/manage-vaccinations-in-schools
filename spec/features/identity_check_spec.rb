# frozen_string_literal: true

describe "HPV vaccination identity check" do
  scenario "Identity confirmed by child (default)" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_a_vaccination_was_given
    and_i_confirm_the_details

    when_i_go_to_the_vaccination_record
    then_i_see_that_child_identified_by_shows_the_child
  end

  scenario "Identity confirmed by someone else" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_confirm_the_patient_identity_was_confirmed_by_someone_else
    and_i_record_a_vaccination_was_given

    and_i_confirm_the_details

    when_i_go_to_the_vaccination_record
    then_i_see_that_child_identified_by_shows_the_person_and_relationship
  end

  scenario "Identity confirmed by someone else for non-vaccination" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_confirm_the_patient_identity_was_confirmed_by_someone_else
    and_i_record_that_the_patient_was_unwell

    and_i_confirm_the_details

    when_i_go_to_the_vaccination_record
    then_i_see_that_child_identified_by_shows_the_person_and_relationship
  end

  scenario "Identity check validation - missing person details" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_select_identity_confirmed_by_someone_else_but_leave_fields_blank
    and_i_try_to_continue
    then_i_see_errors_about_missing_person_name_and_relationship
  end

  scenario "Identity check validation - missing person name only" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_select_identity_confirmed_by_someone_else_with_only_relationship
    and_i_try_to_continue
    then_i_see_error_about_missing_person_name
  end

  scenario "Identity check validation - missing relationship only" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_select_identity_confirmed_by_someone_else_with_only_name
    and_i_try_to_continue
    then_i_see_error_about_missing_person_relationship
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    @organisation = create(:organisation, :with_one_nurse, programmes:)

    location = create(:school)
    @batch =
      create(
        :batch,
        :not_expired,
        organisation: @organisation,
        vaccine: programmes.first.vaccines.active.first
      )

    @session =
      create(:session, organisation: @organisation, programmes:, location:)
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )

    sign_in @organisation.users.first
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def and_i_confirm_the_patient_identity_was_confirmed_by_child
    choose "Yes"
    click_button "Continue"
  end

  def and_i_confirm_the_patient_identity_was_confirmed_by_someone_else
    choose "No, it was confirmed by somebody else"
    fill_in "What is the person’s name?", with: "Sadie Smith"
    fill_in "What is their relationship to the child", with: "teacher"
    click_button "Continue"
  end

  def and_i_record_a_vaccination_was_given
    within all("section")[0] do
      check "has confirmed the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end

    choose @batch.name
    click_button "Continue"
  end

  def and_i_record_that_the_patient_was_unwell
    within all("section")[1] do
      choose "No"
      click_button "Continue"
    end

    choose "They were not well enough"
    click_button "Continue"
  end

  def and_i_confirm_the_details
    click_button "Confirm"
    puts "Vaccination outcome recorded for HPV"
  end

  def when_i_go_to_the_vaccination_record
    click_on Date.current.to_fs(:long)
  end

  def then_i_see_that_child_identified_by_shows_the_child
    expect(page).to have_content("Child identified by")
    expect(page).to have_content("The child")
  end

  def then_i_see_that_child_identified_by_shows_the_person_and_relationship
    expect(page).to have_content("Child identified by")
    expect(page).to have_content("Sadie Smith (teacher)")
  end

  def and_i_try_to_continue
    click_button "Continue"
  end

  def then_i_see_an_error_about_selecting_identity_confirmation
    expect(page).to have_content(
      "Select whether the child confirmed their identity"
    )
  end

  def and_i_select_identity_confirmed_by_someone_else_but_leave_fields_blank
    choose "No, it was confirmed by somebody else"
  end

  def then_i_see_errors_about_missing_person_name_and_relationship
    expect(page).to have_content("Enter the person’s name")
    expect(page).to have_content("Enter the person’s relationship")
  end

  def and_i_select_identity_confirmed_by_someone_else_with_only_relationship
    choose "No, it was confirmed by somebody else"
    fill_in "What is their relationship to the child", with: "teacher"
  end

  def then_i_see_error_about_missing_person_name
    expect(page).to have_content("Enter the person’s name")
    expect(page).not_to have_content("Enter the person’s relationship")
  end

  def and_i_select_identity_confirmed_by_someone_else_with_only_name
    choose "No, it was confirmed by somebody else"
    fill_in "What is the person’s name?", with: "Sadie Smith"
  end

  def then_i_see_error_about_missing_person_relationship
    expect(page).to have_content("Enter the person’s relationship")
    expect(page).not_to have_content("Enter the person’s name")
  end
end
