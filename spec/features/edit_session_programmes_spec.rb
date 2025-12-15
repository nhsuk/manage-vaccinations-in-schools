# frozen_string_literal: true

describe "Edit session programmes" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  before { Flipper.enable(:schools_and_sessions) }

  scenario "choosing programmes with a high number of unvaccinated catch up patients" do
    given_a_school_exists
    and_the_school_has_unvaccinated_catch_up_patients

    when_i_visit_the_school_page
    and_i_create_a_new_session
    and_i_choose_the_programmes
    and_i_choose_the_year_groups
    and_i_choose_the_date
    then_i_see_the_warning_panel_about_unvaccinated_patients

    when_i_click_continue
    then_i_should_see_the_mmr_programme
  end

  def given_a_school_exists
    @team =
      create(:team, :with_one_nurse, programmes: [Programme.hpv, Programme.mmr])

    @location =
      create(:school, team: @team, programmes: [Programme.hpv, Programme.mmr])
  end

  def and_the_school_has_unvaccinated_catch_up_patients
    create_list(
      :patient,
      2,
      :eligible_for_vaccination,
      location: @location,
      year_group: 9,
      programmes: [Programme.hpv, Programme.mmr]
    )
  end

  def when_i_visit_the_school_page
    sign_in @team.users.first
    visit school_sessions_path(@location)
  end

  def and_i_create_a_new_session
    click_on "Add a new session"
  end

  def and_i_choose_the_programmes
    check "HPV"
    check "MMR"
    click_on "Continue"
  end

  def and_i_choose_the_year_groups
    check "Year 8"
    check "Year 9"
    check "Year 10"
    check "Year 11"
    click_on "Continue"
  end

  def and_i_choose_the_date
    fill_in "Year", with: "2024"
    fill_in "Month", with: "2"
    fill_in "Day", with: "8"
    click_on "Continue"
  end

  def then_i_see_the_warning_panel_about_unvaccinated_patients
    expect(page).to have_content(
      "Have you imported historical vaccination records for HPV and MMR?"
    )
    expect(page).to have_content(
      "0% of children in Years 9 to 11 in this session have vaccination " \
        "records."
    )
    expect(page).to have_content(
      "Scheduling this session now will send consent requests to 2 parents " \
        "of children in Years 9 to 11 on 18 January 2024. Many of them may " \
        "be parents of already vaccinated children."
    )
  end

  def when_i_click_continue
    click_on "Keep session dates"
  end

  def then_i_should_see_the_mmr_programme
    within(".nhsuk-summary-list__row", text: "Programmes") do
      expect(page).to have_content("MMR")
    end
  end
end
