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
    and_a_deceased_patient_exists

    when_i_click_on_notices
    then_i_see_the_notice_of_date_of_death
  end

  def given_my_team_exists
    @team = create(:team, :with_one_nurse)
  end

  def and_patients_exist
    create(:patient, team: @team, given_name: "John", family_name: "Smith")
    create_list(:patient, 9, team: @team)
  end

  def and_a_deceased_patient_exists
    @deceased_patient = create(:patient, :deceased, team: @team)
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

  def then_i_see_the_notice_of_date_of_death
    expect(page).to have_content(@deceased_patient.full_name)
    expect(page).to have_content("Record updated with child’s date of death")
  end
end
