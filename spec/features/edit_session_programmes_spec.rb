# frozen_string_literal: true

describe "Edit session programmes" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "add new programme" do
    given_a_session_exists
    and_the_session_has_unvaccinated_catch_up_patients

    when_i_visit_the_session_overview_page
    and_i_click_on_edit_session
    and_i_add_the_mmr_programme
    then_i_see_the_warning_panel_about_unvaccinated_patients

    when_i_click_continue
    then_i_should_see_the_mmr_programme
    screenshot_and_save_page
  end

  def given_a_session_exists
    @team =
      create(:team, :with_one_nurse, programmes: [Programme.hpv, Programme.mmr])
    @session =
      create(:session, :scheduled, programmes: [Programme.hpv], team: @team)
  end

  def and_the_session_has_unvaccinated_catch_up_patients
    create_list(
      :patient,
      2,
      :eligible_for_vaccination,
      session: @session,
      year_group: 9
    )
  end

  def when_i_visit_the_session_overview_page
    sign_in @team.users.first
    visit session_path(@session)
  end

  def and_i_click_on_edit_session
    click_on "Edit session"
  end

  def and_i_add_the_mmr_programme
    within(".nhsuk-summary-list__row", text: "Programmes") { click_on "Change" }
    check "MMR"
    when_i_click_continue
  end

  def then_i_see_the_warning_panel_about_unvaccinated_patients
    expect(page).to have_content(
      "Have you imported historical vaccination records for MMR?"
    )
    expect(page).to have_content(
      "0% of children in Year 1, Year 2, Year 3, Year 4, Year 5, Year 6, " \
        "Year 7, Year 8, Year 9, Year 10, and Year 11 in this session have vaccination records."
    )
    expect(page).to have_content(
      "Scheduling this session now will send consent requests to 2 parents " \
        "of children in Year 1, Year 2, Year 3, Year 4, Year 5, Year 6, Year 7, " \
        "Year 8, Year 9, Year 10, and Year 11 on 18 January 2024. Many of them may " \
        "be parents of already vaccinated children."
    )
  end

  def when_i_click_continue
    click_on "Continue"
  end

  def then_i_should_see_the_mmr_programme
    within(".nhsuk-summary-list__row", text: "Programmes") do
      expect(page).to have_content("MMR")
    end
  end
end
