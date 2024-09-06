# frozen_string_literal: true

describe "Create and edit programmes" do
  before { given_i_am_signed_in }

  scenario "User creates a Flu programme" do
    given_active_flu_vaccines_exist
    and_discontinued_flu_vaccines_exist

    when_i_go_to_the_programmes_page
    and_i_click_on_the_new_programme_button
    then_i_should_see_the_details_page

    when_i_fill_in_flu_details
    and_i_click_continue
    then_i_should_see_the_dates_page

    when_i_fill_in_the_dates
    and_i_click_continue
    then_i_should_see_the_new_confirm_page

    when_i_confirm_the_programme
    then_i_should_see_the_programme_page
    and_i_should_see_the_flu_programme

    when_i_go_to_the_programmes_page
    then_i_should_see_the_flu_programme_and_vaccines
  end

  scenario "User edits a Flu programme" do
    given_a_flu_programme_exists
    and_discontinued_flu_vaccines_exist

    when_i_go_to_the_programmes_page
    and_i_click_on_the_flu_programme
    and_i_click_edit_programme
    then_i_should_see_the_edit_confirm_page

    when_i_click_on_change_name
    and_i_fill_in_flu_details
    and_i_click_continue
    then_i_should_see_the_edit_confirm_page

    when_i_click_on_change_start_date
    and_i_fill_in_the_dates
    and_i_click_continue
    then_i_should_see_the_edit_confirm_page

    when_i_click_on_change_vaccines
    and_i_select_the_flu_vaccines
    and_i_click_continue
    then_i_should_see_the_edit_confirm_page

    when_i_confirm_the_programme
    then_i_should_see_the_programme_page
    and_i_should_see_the_flu_programme
  end

  scenario "User creates an HPV programme" do
    given_active_hpv_vaccines_exist
    and_discontinued_hpv_vaccines_exist

    when_i_go_to_the_programmes_page
    and_i_click_on_the_new_programme_button
    then_i_should_see_the_details_page

    when_i_fill_in_hpv_details
    and_i_click_continue
    then_i_should_see_the_dates_page

    when_i_fill_in_the_dates
    and_i_click_continue
    then_i_should_see_the_new_confirm_page

    when_i_confirm_the_programme
    then_i_should_see_the_programme_page
    and_i_should_see_the_hpv_programme

    when_i_go_to_the_programmes_page
    then_i_should_see_the_hpv_programme_and_vaccines
  end

  scenario "User edits an HPV programme" do
    given_an_hpv_programme_exists
    and_discontinued_hpv_vaccines_exist

    when_i_go_to_the_programmes_page
    and_i_click_on_the_hpv_programme
    and_i_click_edit_programme
    then_i_should_see_the_edit_confirm_page

    when_i_click_on_change_name
    and_i_fill_in_hpv_details
    and_i_click_continue
    then_i_should_see_the_edit_confirm_page

    when_i_click_on_change_start_date
    and_i_fill_in_the_dates
    and_i_click_continue
    then_i_should_see_the_edit_confirm_page

    when_i_click_on_change_vaccines
    and_i_select_the_hpv_vaccines
    and_i_click_continue
    then_i_should_see_the_edit_confirm_page

    when_i_confirm_the_programme
    then_i_should_see_the_programme_page
    and_i_should_see_the_hpv_programme
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def given_active_flu_vaccines_exist
    create(:vaccine, :adjuvanted_quadrivalent)
  end

  def and_discontinued_flu_vaccines_exist
    create(:vaccine, :fluad_tetra)
    create(:vaccine, :flucelvax_tetra)
  end

  def given_active_hpv_vaccines_exist
    create(:vaccine, :gardasil_9)
  end

  def and_discontinued_hpv_vaccines_exist
    create(:vaccine, :cervarix)
    create(:vaccine, :gardasil)
  end

  def given_a_flu_programme_exists
    create(
      :programme,
      :flu,
      name: "Flu - to be renamed",
      academic_year: 2024,
      team: @team
    )
  end

  def given_an_hpv_programme_exists
    create(
      :programme,
      :hpv,
      name: "HPV - to be renamed",
      academic_year: 2024,
      team: @team
    )
  end

  def when_i_go_to_the_programmes_page
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
  end

  def and_i_click_on_the_new_programme_button
    click_on "Create a new vaccination programme"
  end

  def then_i_should_see_the_details_page
    expect(page).to have_content("Programme details")
  end

  def when_i_fill_in_flu_details
    fill_in "Name", with: "Flu"
    choose "Flu"
    choose "2025/26"
  end

  alias_method :and_i_fill_in_flu_details, :when_i_fill_in_flu_details

  def when_i_fill_in_hpv_details
    fill_in "Name", with: "HPV"
    choose "HPV"
    choose "2025/26"
  end

  alias_method :and_i_fill_in_hpv_details, :when_i_fill_in_hpv_details

  def and_i_click_continue
    click_on "Continue"
  end

  def then_i_should_see_the_dates_page
    expect(page).to have_content("When does this programme run?")
  end

  def when_i_fill_in_the_dates
    within all(".nhsuk-fieldset")[0] do
      fill_in "Day", with: "1"
      fill_in "Month", with: "09"
      fill_in "Year", with: "2025"
    end

    within all(".nhsuk-fieldset")[1] do
      fill_in "Day", with: "31"
      fill_in "Month", with: "05"
      fill_in "Year", with: "2026"
    end
  end

  alias_method :and_i_fill_in_the_dates, :when_i_fill_in_the_dates

  def then_i_should_see_the_new_confirm_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("New programme details")
  end

  def when_i_confirm_the_programme
    click_on "Save changes"
  end

  def then_i_should_see_the_programme_page
    expect(page).to have_content("Vaccination programmes")
  end

  def and_i_should_see_the_flu_programme
    expect(page).to have_content("Flu\n2025/26")
  end

  def and_i_should_see_the_hpv_programme
    expect(page).to have_content("HPV\n2025/26")
  end

  def then_i_should_see_the_flu_programme_and_vaccines
    expect(page).to have_content(
      "Name Flu Academic year 2025/26 Vaccines Adjuvanted Quadrivalent - aQIV"
    )
  end

  def then_i_should_see_the_hpv_programme_and_vaccines
    expect(page).to have_content(
      "Name HPV Academic year 2025/26 Vaccines Gardasil 9"
    )
  end

  def and_i_click_on_the_flu_programme
    click_on "Flu"
  end

  def and_i_click_on_the_hpv_programme
    click_on "HPV"
  end

  def and_i_click_edit_programme
    click_on "Edit programme"
  end

  def then_i_should_see_the_edit_confirm_page
    expect(page).to have_content("Edit programme")
    expect(page).to have_content("Programme details")
    expect(page).to have_content("Vaccines")
  end

  def when_i_click_on_change_name
    within(".nhsuk-summary-list__row", text: "Name") { click_on "Change" }
  end

  def when_i_click_on_change_start_date
    within(".nhsuk-summary-list__row", text: "Start date") { click_on "Change" }
  end

  def when_i_click_on_change_vaccines
    within(".nhsuk-summary-list__row", text: "Vaccines") { click_on "Change" }
  end

  def and_i_select_the_flu_vaccines
    check "Fluad Tetra - aQIV"
    check "Flucelvax Tetra - QIVc"
  end

  def and_i_select_the_hpv_vaccines
    check "Cervarix"
    check "Gardasil"
  end
end
