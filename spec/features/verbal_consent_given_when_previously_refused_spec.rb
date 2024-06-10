require "rails_helper"

feature "Verbal consent" do
  include EmailExpectations

  before { Flipper.enable(:parent_contact_method) }

  scenario "Given when previously refused" do
    given_an_hpv_campaign_is_underway
    and_a_parent_has_refused_consent_for_their_child
    and_i_am_logged_in_as_a_nurse

    when_i_check_the_consent_responses_given_for_that_child
    and_i_call_the_parent_that_has_refused_consent
    and_consent_is_given_verbally
    then_i_am_returned_to_the_check_consent_responses_page
    and_i_see_the_success_alert

    when_i_click_on_the_consent_given_tab
    then_i_see_the_child_is_listed

    when_i_visit_the_patient_page
    then_i_see_that_consent_is_given
  end

  def given_an_hpv_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team: @team)
    location = create(:location, name: "Pilot School", team: @team)
    @session =
      create(:session, :in_future, campaign:, location:, patients_in_session: 0)
  end

  def and_a_parent_has_refused_consent_for_their_child
    @child =
      create(:patient_session, :consent_refused, session: @session).patient
  end

  def and_i_am_logged_in_as_a_nurse
    sign_in @team.users.first
  end

  def when_i_check_the_consent_responses_given_for_that_child
    visit "/dashboard"
    click_on "Campaigns", match: :first
    click_on "HPV"
    click_on "Pilot School"
    click_on "Check consent responses"
    click_on "Refused"
    click_on @child.full_name
  end

  def and_i_call_the_parent_that_has_refused_consent
    click_on "Get consent"

    expect(page).to have_field("Full name", with: @child.parent.name)

    # contacting the same parent who refused
    fill_in "Phone number",
            with: @session.patient_sessions.first.consents.first.parent.phone
    fill_in "Full name",
            with: @session.patient_sessions.first.consents.first.parent.name
    # relationship to the child
    choose @session
             .patient_sessions
             .first
             .consents
             .first
             .parent
             .relationship_label
             .capitalize

    click_button "Continue"
  end

  def and_consent_is_given_verbally
    choose "By phone"
    click_button "Continue"

    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".edit_consent .nhsuk-fieldset")[0].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[1].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    click_button "Confirm"
  end

  def then_i_am_returned_to_the_check_consent_responses_page
    expect(page).to have_content("Check consent responses")
  end

  def and_i_see_the_success_alert
    expect(page).to have_alert(
      "Success",
      text: "Consent recorded for #{@child.full_name}"
    )
  end

  def when_i_click_on_the_consent_given_tab
    click_on "Given"
  end

  def then_i_see_the_child_is_listed
    expect(page).to have_content(@child.full_name)
  end

  def when_i_visit_the_patient_page
    click_on @child.full_name
  end

  def then_i_see_that_consent_is_given
    expect(page).to have_content("Safe to vaccinate")
  end
end
