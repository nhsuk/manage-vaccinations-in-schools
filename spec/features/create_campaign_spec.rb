# frozen_string_literal: true

describe "Create campaign" do
  before do
    given_i_am_signed_in
    and_active_and_discontinued_vaccines_exist
  end

  scenario "User creates a Flu campaign" do
    when_i_go_to_the_campaigns_page
    and_i_click_on_the_new_campaign_button
    then_i_should_see_the_details_page

    when_i_fill_in_flu_details
    and_i_click_continue
    then_i_should_see_the_dates_page

    when_i_fill_in_the_dates
    and_i_click_continue
    then_i_should_see_the_confirm_page

    when_i_confirm_the_campaign
    then_i_should_see_the_campaign_page
    and_i_should_see_the_flu_campaign

    when_i_go_to_the_campaigns_page
    then_i_should_see_the_flu_campaign_and_vaccines
  end

  scenario "User creates an HPV campaign" do
    when_i_go_to_the_campaigns_page
    and_i_click_on_the_new_campaign_button
    then_i_should_see_the_details_page

    when_i_fill_in_hpv_details
    and_i_click_continue
    then_i_should_see_the_dates_page

    when_i_fill_in_the_dates
    and_i_click_continue
    then_i_should_see_the_confirm_page

    when_i_confirm_the_campaign
    then_i_should_see_the_campaign_page
    and_i_should_see_the_hpv_campaign

    when_i_go_to_the_campaigns_page
    then_i_should_see_the_hpv_campaign_and_vaccines
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_active_and_discontinued_vaccines_exist
    create(:vaccine, :gardasil_9)
    create(:vaccine, :gardasil)

    create(:vaccine, :fluenz_tetra)
    create(:vaccine, :fluad_tetra)
  end

  def when_i_go_to_the_campaigns_page
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
  end

  def and_i_click_on_the_new_campaign_button
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

  def when_i_fill_in_hpv_details
    fill_in "Name", with: "HPV"
    choose "HPV"
    choose "2025/26"
  end

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

  def then_i_should_see_the_confirm_page
    expect(page).to have_content("Check and confirm")
  end

  def when_i_confirm_the_campaign
    click_on "Save changes"
  end

  def then_i_should_see_the_campaign_page
    expect(page).to have_content("Vaccination programmes")
  end

  def and_i_should_see_the_flu_campaign
    expect(page).to have_content("Flu\n2025/26")
  end

  def and_i_should_see_the_hpv_campaign
    expect(page).to have_content("HPV\n2025/26")
  end

  def then_i_should_see_the_flu_campaign_and_vaccines
    expect(page).to have_content(
      "Name Flu Academic year 2025/26 Vaccines Fluenz Tetra - LAIV"
    )
  end

  def then_i_should_see_the_hpv_campaign_and_vaccines
    expect(page).to have_content(
      "Name HPV Academic year 2025/26 Vaccines Gardasil 9"
    )
  end
end
