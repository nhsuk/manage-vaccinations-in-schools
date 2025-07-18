# frozen_string_literal: true

describe "Parental consent manual matching" do
  before { given_the_app_is_setup }

  scenario "Consent isn't matched automatically so nurse matches it manually" do
    when_i_go_to_the_dashboard
    and_i_click_on_unmatched_consent_responses
    then_i_am_on_the_unmatched_responses_page
    and_i_see_one_response

    when_i_choose_a_consent_response
    then_i_am_on_the_consent_matching_page

    when_i_search_for_the_child
    and_i_select_the_child_record
    then_i_can_review_the_match

    when_i_link_the_response_with_the_record
    and_i_click_on_the_patient
    then_the_parent_consent_is_shown

    when_i_click_on_the_activity_log
    then_i_see_the_consent_was_matched_manually
  end

  scenario "Consent is marked as invalid" do
    when_i_go_to_the_dashboard
    and_i_click_on_unmatched_consent_responses
    then_i_am_on_the_unmatched_responses_page
    and_i_see_one_response

    when_i_choose_to_archive_the_response
    then_i_fill_in_the_notes
    and_i_archive_the_response

    then_i_am_on_the_unmatched_responses_page
    and_i_see_the_archived_message
    and_i_see_no_responses
  end

  def given_the_app_is_setup
    programmes = [create(:programme, :hpv)]

    @organisation = create(:organisation, :with_one_nurse, programmes:)
    @user = @organisation.users.first
    @school = create(:school, name: "Pilot School", organisation: @organisation)
    @session =
      create(
        :session,
        location: @school,
        organisation: @organisation,
        programmes:
      )
    @consent_form =
      create(
        :consent_form,
        :recorded,
        session: @session,
        parent_full_name: "John Smith"
      )
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
  end

  def and_i_see_one_response
    expect(page).to have_content("1 unmatched consent response")
  end

  def when_i_choose_a_consent_response
    click_on "Match"
  end

  def then_i_am_on_the_consent_matching_page
    expect(page).to have_content("Search for a child record")
  end

  def when_i_search_for_the_child
    fill_in "Search", with: @patient.given_name
    click_button "Search"
  end

  def and_i_select_the_child_record
    click_link @patient.full_name
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

  def when_i_click_on_the_activity_log
    click_on "Session activity and notes"
  end

  def then_i_see_the_consent_was_matched_manually
    expect(page).to have_content(
      "Consent response manually matched with child record"
    )
  end

  def when_i_choose_to_archive_the_response
    click_on "Archive"
  end

  def then_i_fill_in_the_notes
    fill_in "Notes", with: "Some notes."
  end

  def and_i_archive_the_response
    click_on "Archive response"
  end

  def and_i_see_the_archived_message
    expect(page).to have_content("Consent response from John Smith archived")
  end

  def and_i_see_no_responses
    expect(page).to have_content(
      "There are currently no unmatched consent responses."
    )
  end
end
