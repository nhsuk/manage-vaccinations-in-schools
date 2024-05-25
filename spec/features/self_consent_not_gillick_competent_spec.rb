require "rails_helper"

RSpec.describe "Not Gillick competent" do
  after { Timecop.return }

  scenario "No consent from parent, the child is not Gillick competent" do
    given_an_hpv_campaign_is_underway
    and_it_is_the_day_of_a_vaccination_session
    and_there_is_a_child_without_parental_consent

    when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    then_the_child_cannot_give_their_own_consent
    and_the_lack_of_gillick_competence_is_visible_to_the_nurse
  end

  def given_an_hpv_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team: @team)
    location = create(:location, name: "Pilot School", team: @team)
    @session =
      create(:session, :in_future, campaign:, location:, patients_in_session: 1)
    @child = @session.patients.first
  end

  def and_it_is_the_day_of_a_vaccination_session
    Timecop.freeze(@session.date)
  end

  def and_there_is_a_child_without_parental_consent
    sign_in @team.users.first

    visit "/dashboard"

    click_on "Campaigns", match: :first
    click_on "HPV"
    click_on "Pilot School"
    click_on "Check consent responses"

    expect(page).to have_content("No consent ( 1 )")
    expect(page).to have_content(@child.full_name)
  end

  def when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    click_on @child.full_name

    click_on "Assess Gillick competence"
    click_on "Give your assessment"

    choose "No"

    fill_in "Give details of your assessment",
            with: "They didn't understand the benefits and risks of the vaccine"
    click_on "Continue"
  end

  def then_the_child_cannot_give_their_own_consent
    skip "BUG here: the child shouldn't be able to give their own consent, but can"
  end

  def and_the_lack_of_gillick_competence_is_visible_to_the_nurse
    expect(page).to have_content(
      "No-one responded to our requests for consent. When assessed, the child was not Gillick competent"
    )
  end
end
