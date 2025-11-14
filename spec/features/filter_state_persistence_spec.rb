# frozen_string_literal: true

describe "Filter states" do
  scenario "filters are perisisted and maintain state across navigation" do
    given_i_am_signed_in

    when_i_visit_the_consent_page
    and_i_apply_consent_filters
    then_the_consent_filters_are_applied

    when_i_navigate_to_another_page
    and_i_return_to_the_consent_page
    then_the_consent_filters_are_still_applied

    when_i_clear_the_consent_filters
    then_i_should_see_no_applied_filters

    when_i_visit_the_triage_page
    and_i_apply_triage_filters
    then_the_triage_filters_are_applied

    when_i_navigate_to_another_page
    and_i_return_to_the_triage_page
    then_the_triage_filters_are_still_applied

    when_i_visit_the_consent_page
    then_i_should_see_no_applied_filters
  end

  scenario "preset filters are applied" do
    given_i_am_signed_in

    when_i_visit_the_session_overview_page
    and_i_click_the_no_consent_response_link
    then_the_no_consent_response_filter_is_applied

    when_i_visit_the_session_overview_page
    and_i_click_the_conflicting_consent_link
    then_the_conflicting_consent_filter_is_applied

    when_i_visit_the_session_overview_page
    and_i_click_the_triage_needed_link
    then_the_triage_needed_filter_is_applied

    when_i_visit_the_session_overview_page
    and_i_click_the_register_attendance_link
    then_the_not_registered_yet_filter_is_applied

    when_i_visit_the_session_overview_page
    and_i_click_the_ready_for_vaccinator_link
    then_i_should_be_on_the_record_page
  end

  def given_i_am_signed_in
    @programme = CachedProgramme.hpv
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    @session = create(:session, team: @team, programmes: [@programme])

    create(:patient, :consent_no_response, session: @session)
    create(:patient, :consent_conflicting, session: @session)
    create(:patient, :consent_refused, session: @session)
    create(:patient, :consent_given_triage_needed, session: @session)
    create(
      :patient,
      :consent_given_triage_not_needed,
      :in_attendance,
      session: @session
    )
    create(:patient, :unknown_attendance, session: @session)
    create(:patient, :vaccinated, session: @session)

    sign_in @team.users.first
  end

  def when_i_visit_the_consent_page
    visit session_consent_path(@session)
  end

  def and_i_apply_consent_filters
    check "Consent given"
    click_on "Update results"
  end

  def when_i_visit_the_session_overview_page
    visit session_path(@session)
  end

  def and_i_click_the_no_consent_response_link
    click_on "1 child with no response"
  end

  def and_i_click_the_conflicting_consent_link
    click_on "1 child with conflicting response"
  end

  def and_i_click_the_triage_needed_link
    click_on "1 child requiring triage"
  end

  def and_i_click_the_register_attendance_link
    click_on "1 child to register"
  end

  def and_i_click_the_ready_for_vaccinator_link
    click_on "1 child for #{@programme.name}"
  end

  def then_i_should_be_on_the_record_page
    expect(page).to have_current_path(
      session_record_path(@session, programme_types: [@programme.type])
    )
  end

  def then_the_vaccinated_filter_is_applied
    expect(page).to have_checked_field("Vaccinated")
  end

  def then_the_consent_refused_filter_is_applied
    expect(page).to have_checked_field("Consent refused")
  end

  def then_the_no_consent_response_filter_is_applied
    expect(page).to have_checked_field("No response")
  end

  def then_the_consent_filters_are_applied
    expect(page).to have_checked_field("Consent given")
  end

  def then_the_consent_filters_are_still_applied
    expect(page).to have_checked_field("Consent given")
  end

  def then_the_conflicting_consent_filter_is_applied
    expect(page).to have_checked_field("Conflicting consent")
  end

  def then_the_triage_needed_filter_is_applied
    expect(page).to have_checked_field("Needs triage")
  end

  def then_the_not_registered_yet_filter_is_applied
    expect(page).to have_checked_field("Not registered yet")
  end

  def when_i_clear_the_consent_filters
    click_on "Clear filters"
  end

  def when_i_navigate_to_another_page
    visit root_path
  end

  def and_i_return_to_the_consent_page
    visit session_consent_path(@session)
  end

  def when_i_visit_the_triage_page
    visit session_triage_path(@session)
  end

  def and_i_apply_triage_filters
    choose "Safe to vaccinate"
    click_on "Update results"
  end

  def then_the_triage_filters_are_applied
    expect(page).to have_checked_field("Safe to vaccinate")
  end

  def and_i_return_to_the_triage_page
    visit session_triage_path(@session)
  end

  def then_the_triage_filters_are_still_applied
    expect(page).to have_checked_field("Safe to vaccinate")
  end

  def when_i_clear_the_triage_filters
    click_on "Clear filters"
  end

  def then_i_should_see_no_applied_filters
    expect(page).not_to have_checked_field
  end
end
