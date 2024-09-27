# frozen_string_literal: true

describe "Parental consent school" do
  before { Flipper.enable(:consent_form_choose_school) }

  scenario "Child attends a different school" do
    given_an_hpv_programme_is_underway
    when_i_go_to_the_consent_form
    when_i_fill_in_my_childs_name_and_birthday

    when_i_do_not_confirm_they_attend_the_pilot_school
    then_i_see_a_page_asking_for_the_childs_school

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_a_school
    then_i_see_the_parent_step
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @team = create(:team, :with_one_nurse, programmes: [programme])
    location = create(:location, :school, team: @team, name: "Pilot School")
    @session = create(:session, :scheduled, team: @team, programme:, location:)
    @child = create(:patient, session: @session)
  end

  def when_i_go_to_the_consent_form
    visit start_session_parent_interface_consent_forms_path(@session)
  end

  def when_i_fill_in_my_childs_name_and_birthday
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.first_name
    fill_in "Last name", with: @child.last_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"
  end

  def when_i_do_not_confirm_they_attend_the_pilot_school
    choose "No, they go to a different school"
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
end
