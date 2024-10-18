# frozen_string_literal: true

describe "Manage children" do
  scenario "Viewing children" do
    given_my_team_exists
    and_patients_exist

    when_i_click_on_children
    then_i_see_the_children

    when_i_click_on_a_child
    then_i_see_the_child
  end

  scenario "Viewing important notices" do
    given_my_team_exists

    when_i_click_on_notices
    then_i_see_no_notices

    when_a_deceased_patient_exists
    and_an_invalid_patient_exists
    and_a_restricted_patient_exists
    and_i_click_on_notices
    then_i_see_the_notice_of_date_of_death
    and_i_see_the_notice_of_invalid
    and_i_see_the_notice_of_sensitive
  end

  def given_my_team_exists
    @team = create(:team, :with_one_nurse)
  end

  def and_patients_exist
    create(:patient, team: @team, given_name: "John", family_name: "Smith")
    create_list(:patient, 9, team: @team)
  end

  def when_a_deceased_patient_exists
    @deceased_patient = create(:patient, :deceased, team: @team)
  end

  def and_an_invalid_patient_exists
    @invalidated_patient = create(:patient, :invalidated, team: @team)
  end

  def and_a_restricted_patient_exists
    @restricted_patient = create(:patient, :restricted, team: @team)
  end

  def when_i_click_on_children
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Children", match: :first
  end

  def then_i_see_the_children
    expect(page).to have_content("10 children")
  end

  def when_i_click_on_a_child
    click_on "John Smith"
  end

  def then_i_see_the_child
    expect(page).to have_title("JS")
    expect(page).to have_content("John Smith")
  end

  def when_i_click_on_notices
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Notices"
  end

  alias_method :and_i_click_on_notices, :when_i_click_on_notices

  def then_i_see_no_notices
    expect(page).to have_content("There are currently no important notices.")
  end

  def then_i_see_the_notice_of_date_of_death
    expect(page).to have_content(@deceased_patient.full_name)
    expect(page).to have_content("Record updated with child’s date of death")
  end

  def and_i_see_the_notice_of_invalid
    expect(page).to have_content(@invalidated_patient.full_name)
    expect(page).to have_content("Record flagged as invalid")
  end

  def and_i_see_the_notice_of_sensitive
    expect(page).to have_content(@restricted_patient.full_name)
    expect(page).to have_content("Record flagged as sensitive")
  end
end
