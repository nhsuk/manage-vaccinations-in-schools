# frozen_string_literal: true

describe "User authorisation" do
  scenario "Users are unable to access other teams' pages" do
    given_an_hpv_campaign_is_underway_with_two_teams
    when_i_sign_in_as_a_nurse_from_one_team
    and_i_go_to_the_consent_page
    then_i_should_only_see_my_patients

    when_i_go_to_the_session_page_of_another_team
    then_i_should_see_page_not_found

    when_i_go_to_the_consent_page_of_another_team
    then_i_should_see_page_not_found

    when_i_go_to_the_patient_page_of_another_team
    then_i_should_see_page_not_found
  end

  def given_an_hpv_campaign_is_underway_with_two_teams
    @team = create(:team, :with_one_nurse)
    @other_team = create(:team, :with_one_nurse)
    vaccine = create(:vaccine, :hpv)
    campaign = create(:campaign, :hpv, team: @team, vaccines: [vaccine])
    other_campaign =
      create(:campaign, :hpv, team: @other_team, vaccines: [vaccine])
    location = create(:location, :school, name: "Pilot School")
    other_location = create(:location, :school, name: "Other School")
    @session = create(:session, :in_future, campaign:, location:)
    @other_session =
      create(
        :session,
        :in_future,
        campaign: other_campaign,
        location: other_location
      )
    @child = create(:patient, session: @session)
    @other_child = create(:patient, session: @other_session)
  end

  def when_i_sign_in_as_a_nurse_from_one_team
    sign_in @team.users.first
  end

  def and_i_go_to_the_consent_page
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "School sessions"
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_i_should_only_see_my_patients
    expect(page).to have_content(@child.full_name)
    expect(page).not_to have_content(@other_child.full_name)
  end

  def when_i_go_to_the_consent_page_of_another_team
    visit "/sessions/#{@other_session.id}/consent"
  end

  def then_i_should_see_page_not_found
    expect(page).to have_content("Page not found")
  end

  def when_i_go_to_the_session_page_of_another_team
    visit "/sessions/#{@other_session.id}"
  end

  def when_i_go_to_the_consent_page_of_another_team
    visit "/sessions/#{@other_session.id}/consent"
  end

  def when_i_go_to_the_patient_page_of_another_team
    visit "/patients/#{@other_session.id}/consent/given/patients/#{@other_child.id}"
  end
end
