# frozen_string_literal: true

describe "Programmes index" do
  around { |example| travel_to(Date.new(2024, 5, 20)) { example.run } }

  scenario "Viewing all programmes" do
    given_an_team_exists_that_administered_all_programmes

    when_i_visit_the_programmes_page
    then_i_see_the_programmes_in_alphabetical_order
  end

  def given_an_team_exists_that_administered_all_programmes
    programmes = [
      CachedProgramme.hpv,
      CachedProgramme.menacwy,
      CachedProgramme.td_ipv
    ]

    @team = create(:team, programmes:)
  end

  def when_i_visit_the_programmes_page
    user = create(:nurse, teams: [@team])

    sign_in user
    visit dashboard_path
    click_on "Programmes", match: :first
  end

  def then_i_see_the_programmes_in_alphabetical_order
    cohort_cards = page.all(".nhsuk-table__cell a")
    expect(cohort_cards[0]).to have_content("HPV")
    expect(cohort_cards[1]).to have_content("MenACWY")
    expect(cohort_cards[2]).to have_content("Td/IPV")
  end
end
