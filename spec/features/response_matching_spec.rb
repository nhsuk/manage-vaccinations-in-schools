# frozen_string_literal: true

describe "Response matching" do
  scenario "Users can match responses to patient records" do
    given_the_app_is_setup

    when_i_go_to_the_dashboard
    and_i_click_on_unmatched_consent_responses
    then_i_am_on_the_unmatched_responses_page

    when_i_choose_a_consent_response
    then_i_am_on_the_consent_matching_page

    when_i_select_a_child_record
    then_i_can_review_the_match

    when_i_link_the_response_with_the_record
    and_i_click_on_the_patient
    then_the_parent_consent_is_shown
  end

  def given_the_app_is_setup
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    @user = @organisation.users.first
    @school = create(:location, :school, name: "Pilot School")
    @session =
      create(
        :session,
        location: @school,
        organisation: @organisation,
        programme: @programme
      )
    @consent_form =
      create(:consent_form, :recorded, programme: @programme, session: @session)
    @patient = create(:patient, session: @session)
  end

  def when_i_go_to_the_dashboard
    sign_in @user
    visit dashboard_path
  end

  def and_i_click_on_unmatched_consent_responses
    click_on "Unmatched consent responses"
  end

  def then_i_am_on_the_unmatched_responses_page
    expect(page).to have_content("Unmatched consent responses")
    expect(page).to have_content("1 consent response")
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

  def and_i_click_on_the_patient
    click_on @patient.full_name
  end

  def then_the_parent_consent_is_shown
    expect(page).to have_content(@consent_form.parent_full_name)
  end
end
