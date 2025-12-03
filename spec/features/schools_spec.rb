# frozen_string_literal: true

describe "Schools" do
  scenario "Filtering on schools and viewing sessions" do
    given_the_feature_flag_is_enabled
    and_a_team_exists_with_a_few_schools
    and_i_am_signed_in

    when_i_visit_the_dashboard
    then_i_can_see_the_schools_link

    when_i_click_on_the_schools_link
    then_i_see_both_schools
    and_i_can_see_the_unknown_school

    when_i_filter_on_primary_schools
    then_i_see_only_the_primary_school

    when_i_filter_on_secondary_schools
    then_i_see_only_the_secondary_school

    when_i_click_on_the_secondary_school
    then_i_see_the_secondary_patients

    when_i_click_on_sessions
    then_i_see_the_secondary_sessions
  end

  def given_the_feature_flag_is_enabled
    Flipper.enable(:schools_and_sessions)
  end

  def and_a_team_exists_with_a_few_schools
    programmes = [Programme.flu, Programme.hpv]

    @team = create(:team, :with_generic_clinic, programmes:)

    @primary_school = create(:school, :primary, team: @team)
    @secondary_school = create(:school, :secondary, team: @team)

    @primary_session =
      create(:session, :yesterday, location: @primary_school, team: @team)
    @secondary_session =
      create(:session, :tomorrow, location: @secondary_school, team: @team)

    @primary_patient =
      create(:patient, year_group: 1, session: @primary_session)
    @secondary_patient =
      create(:patient, year_group: 7, session: @secondary_session)

    @nurse = create(:nurse, team: @team)
  end

  def and_i_am_signed_in = sign_in @nurse

  def when_i_visit_the_dashboard
    visit dashboard_path
  end

  def then_i_can_see_the_schools_link
    expect(page).to have_link("Schools").twice
  end

  def when_i_click_on_the_schools_link
    click_link "Schools", match: :first
  end

  def then_i_see_both_schools
    expect(page).to have_content(@primary_school.name)
    expect(page).to have_content(@secondary_school.name)
  end

  def and_i_can_see_the_unknown_school
    expect(page).to have_content("No known school")
  end

  def when_i_filter_on_primary_schools
    choose "Primary"
    click_on "Update results"
  end

  def then_i_see_only_the_primary_school
    expect(page).to have_content(@primary_school.name)
    expect(page).not_to have_content(@secondary_school.name)
  end

  def when_i_filter_on_secondary_schools
    choose "Secondary"
    click_on "Update results"
  end

  def then_i_see_only_the_secondary_school
    expect(page).not_to have_content(@primary_school.name)
    expect(page).to have_content(@secondary_school.name)
  end

  def when_i_click_on_the_secondary_school
    click_on @secondary_school.name
  end

  def then_i_see_the_secondary_patients
    expect(page).not_to have_content(@primary_patient.full_name)
    expect(page).to have_content(@secondary_patient.full_name)
  end

  def when_i_click_on_sessions
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
  end

  def then_i_see_the_secondary_sessions
    expect(page).to have_content(Date.tomorrow.to_fs(:long))
  end
end
