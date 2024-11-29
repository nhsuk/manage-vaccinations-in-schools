# frozen_string_literal: true

describe "Parental consent school" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "Child attending a clinic goes to a school" do
    stub_pds_search_to_return_no_patients

    given_an_hpv_programme_is_underway

    when_i_go_to_the_consent_form
    and_i_fill_in_my_childs_name_and_birthday
    then_i_see_a_page_asking_if_my_child_is_home_educated

    when_i_choose_no_they_go_to_a_school
    then_i_see_a_page_asking_for_the_childs_school

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_a_school
    then_i_see_the_parent_step

    when_i_give_consent
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers

    when_i_submit_the_consent_form
    then_i_see_a_confirmation_page

    when_the_nurse_checks_the_community_clinic
    then_the_nurse_should_see_one_mover
    and_the_nurse_confirms_the_mover

    when_the_nurse_checks_the_patient
    then_the_nurse_should_see_the_school
  end

  scenario "Child attending a clinic is home-schooled" do
    stub_pds_search_to_return_no_patients

    given_an_hpv_programme_is_underway

    when_i_go_to_the_consent_form
    and_i_fill_in_my_childs_name_and_birthday
    then_i_see_a_page_asking_if_my_child_is_home_educated

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_yes
    then_i_see_the_parent_step

    when_i_give_consent
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers

    when_i_submit_the_consent_form
    then_i_see_a_confirmation_page

    when_the_nurse_checks_the_community_clinic
    then_the_nurse_should_see_one_mover
    and_the_nurse_confirms_the_mover

    when_the_nurse_checks_the_patient
    then_the_nurse_should_see_home_schooled
  end

  scenario "Child attending a clinic is not in education" do
    stub_pds_search_to_return_no_patients

    given_an_hpv_programme_is_underway

    when_i_go_to_the_consent_form
    and_i_fill_in_my_childs_name_and_birthday
    then_i_see_a_page_asking_if_my_child_is_home_educated

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_no_they_are_not_in_education
    then_i_see_the_parent_step

    when_i_give_consent
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers

    when_i_submit_the_consent_form
    then_i_see_a_confirmation_page

    when_the_nurse_checks_the_community_clinic
    then_the_nurse_should_see_no_movers

    when_the_nurse_checks_the_patient
    then_the_nurse_should_see_unknown_school
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    location = create(:generic_clinic, organisation: @organisation)

    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programme: @programme,
        location:
      )

    @child = create(:patient, session: @session)

    create(:school, organisation: @organisation, name: "Pilot School")
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def and_i_fill_in_my_childs_name_and_birthday
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.given_name
    fill_in "Last name", with: @child.family_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"
  end

  def then_i_see_a_page_asking_if_my_child_is_home_educated
    expect(page).to have_heading("Is your child home-schooled?")
  end

  def when_i_choose_no_they_go_to_a_school
    choose "No, they go to a school"
    click_on "Continue"
  end

  def when_i_choose_no_they_are_not_in_education
    choose "No, they are not in education"
    click_on "Continue"
  end

  def when_i_choose_yes
    choose "Yes"
    click_on "Continue"
  end

  def then_i_see_a_page_asking_for_the_childs_school
    expect(page).to have_heading("What school does your child go to?")
  end

  def when_i_click_continue
    click_on "Continue"
  end

  def then_i_see_an_error
    expect(page).to have_heading "There is a problem"
  end

  def when_i_choose_a_school
    select "Pilot School"
    click_on "Continue"
  end

  def then_i_see_the_parent_step
    expect(page).to have_heading "About you"
  end

  def when_i_give_consent
    expect(page).to have_content("About you")
    fill_in "Your name", with: "Jane #{@child.family_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"
    check "Tick this box if you’d like to get updates by text message"
    click_on "Continue"

    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"
    click_on "Continue"

    expect(page).to have_content("Do you agree")
    choose "Yes, I agree"
    click_on "Continue"

    expect(page).to have_content("Is your child registered with a GP?")
    choose "Yes, they are registered with a GP"
    fill_in "Name of GP surgery", with: "GP Surgery"
    click_on "Continue"

    expect(page).to have_content("Home address")
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "TE1 1ST"
    click_on "Continue"
  end

  def and_i_answer_no_to_all_the_medical_questions
    until page.has_content?("Check your answers and confirm")
      choose "No"
      click_on "Continue"
    end
  end

  def then_i_can_check_my_answers
    expect(page).to have_content("Check your answers and confirm")
    expect(page).to have_content("Child’s name#{@child.full_name}")
  end

  def when_i_submit_the_consent_form
    click_on "Confirm"
  end

  def then_i_see_a_confirmation_page
    # TODO: "will get their HPV vaccination at the clinic"
    expect(page).to have_content("will get their HPV vaccination")

    perform_enqueued_jobs # match consent form with patient
  end

  def when_the_nurse_checks_the_community_clinic
    sign_in @organisation.users.first
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Community clinics"
  end

  def then_the_nurse_should_see_one_mover
    expect(page).to have_content("Review children who have changed schools")
  end

  def and_the_nurse_confirms_the_mover
    click_on "Review children who have changed schools"
    click_on "Moved out"
    expect(page).to have_content(@child.full_name)
    click_on "Confirm"
    click_on "Back"
  end

  def then_the_nurse_should_see_no_movers
    expect(page).not_to have_content("Review children who have changed schools")
  end

  def when_the_nurse_checks_the_patient
    click_on "Record vaccinations"
    click_on @child.full_name
  end

  def then_the_nurse_should_see_the_school
    expect(page).to have_content("SchoolPilot School")
  end

  def then_the_nurse_should_see_home_schooled
    expect(page).to have_content("SchoolHome-schooled")
  end

  def then_the_nurse_should_see_unknown_school
    expect(page).to have_content("SchoolUnknown")
  end
end
