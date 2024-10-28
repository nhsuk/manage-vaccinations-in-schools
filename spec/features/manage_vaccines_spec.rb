# frozen_string_literal: true

describe "Manage vaccines" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "Viewing a vaccine" do
    given_my_team_is_running_an_hpv_vaccination_programme

    when_i_manage_vaccines
    then_i_see_an_hpv_vaccine_listed
    when_i_click_on_the_vaccine
    then_i_see_the_vaccine_details

    when_i_click_back
    then_i_see_the_vaccine_list
  end

  def given_my_team_is_running_an_hpv_vaccination_programme
    programme = create(:programme, :hpv)
    @team = create(:team, :with_one_nurse, programmes: [programme])
  end

  def when_i_manage_vaccines
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Vaccines", match: :first
  end

  def then_i_see_an_hpv_vaccine_listed
    expect(page).to have_content("Gardasil 9 (HPV)")
  end

  def when_i_click_on_the_vaccine
    click_on "Gardasil 9 (HPV)"
  end

  def then_i_see_the_vaccine_details
    expect(page).to have_selector :heading, "Gardasil 9 (HPV)"
    expect(page).to have_selector :heading, "Vaccine details"
  end

  def when_i_click_back
    click_on "Back"
  end

  def then_i_see_the_vaccine_list
    expect(page).to have_selector :heading, "Vaccines"
  end
end
