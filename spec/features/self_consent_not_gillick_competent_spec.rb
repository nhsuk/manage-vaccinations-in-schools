# frozen_string_literal: true

describe "Not Gillick competent" do
  after { travel_back }

  scenario "No consent from parent, the child is not Gillick competent" do
    given_an_hpv_programme_is_underway
    and_it_is_the_day_of_a_vaccination_session
    and_there_is_a_child_without_parental_consent

    when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    then_the_child_cannot_give_their_own_consent
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @team =
      create(
        :team,
        :with_one_nurse,
        programmes: [programme],
        nurse_email: "nurse.joy@example.com"
      )
    location = create(:location, :school, name: "Pilot School")
    @session = create(:session, :scheduled, team: @team, programme:, location:)
    @child = create(:patient, session: @session)
  end

  def and_it_is_the_day_of_a_vaccination_session
    travel_to(@session.dates.first.value)
  end

  def and_there_is_a_child_without_parental_consent
    sign_in @team.users.first

    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Check consent responses"

    expect(page).to have_content("No response ( 1 )")
    expect(page).to have_content(@child.full_name)
  end

  def when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    click_on @child.full_name

    click_link "Give your assessment"
    click_button "Give your assessment"

    choose "No"
    click_on "Continue"

    fill_in "Details of your assessment",
            with: "They didn't understand the benefits and risks of the vaccine"
    click_on "Continue"

    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(["Are they Gillick competent?", "No"].join)
    expect(page).to have_content(
      [
        "Details of your assessment",
        "They didn't understand the benefits and risks of the vaccine"
      ].join
    )
    click_on "Save changes"
  end

  def then_the_child_cannot_give_their_own_consent
    click_on "Get consent"
    expect(page).to have_content("Who are you trying to get consent from?")
    expect(page).not_to have_content(
      "Do they agree to them having the HPV vaccination?"
    )
  end
end
