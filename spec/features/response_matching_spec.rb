# frozen_string_literal: true

require "rails_helper"

describe "Response matching" do
  scenario "Users can match responses to patient records" do
    given_the_app_is_setup
    when_i_go_to_the_campaigns_page
    and_i_click_on_the_check_consent_responses_link
    then_i_see_the_unmatched_responses_link

    when_i_click_on_the_unmatched_responses_link
    then_i_am_on_the_unmatched_responses_page

    when_i_choose_a_consent_response
    then_i_am_on_the_consent_matching_page

    when_i_select_a_child_record
    then_i_can_review_the_match

    when_i_link_the_response_with_the_record
    and_i_go_to_the_consent_given_page
    then_the_matched_cohort_appears_in_the_consent_given_list
  end

  def given_the_app_is_setup
    @team = create(:team, :with_one_nurse)
    @user = @team.users.first
    @campaign = create(:campaign, :hpv, team: @team)
    @school = create(:location, :school, name: "Pilot School")
    @session =
      create(
        :session,
        location: @school,
        campaign: @campaign,
        patients_in_session: 1
      )
    @consent_form = create(:consent_form, :recorded, session: @session)
    @patient = @session.patients.first
  end

  def when_i_go_to_the_campaigns_page
    sign_in @user
    visit campaigns_path
  end

  def and_i_click_on_the_check_consent_responses_link
    click_on @campaign.name
    click_on "School sessions"
    click_on @school.name
    click_on "Check consent responses"
  end

  def then_i_see_the_unmatched_responses_link
    expect(page).to have_link(
      "1 response needs matching with records in the cohort"
    )
  end

  def when_i_click_on_the_unmatched_responses_link
    click_on "1 response needs matching with records in the cohort"
  end

  def then_i_am_on_the_unmatched_responses_page
    expect(page).to have_content("Unmatched consent responses")
  end

  def when_i_choose_a_consent_response
    click_on "Find match"
  end

  def then_i_am_on_the_consent_matching_page
    expect(page).to have_content("Search for a child record")
  end

  def when_i_select_a_child_record
    click_link "Select"
  end

  def then_i_can_review_the_match
    expect(page).to have_content("Link consent response with child record?")
  end

  def when_i_link_the_response_with_the_record
    click_on "Link response with record"
  end

  def and_i_go_to_the_consent_given_page
    click_on "Given"
  end

  def then_the_matched_cohort_appears_in_the_consent_given_list
    expect(page).to have_content @patient.first_name
  end
end
